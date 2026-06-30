import Foundation
import Network
import os.log

private let log = OSLog(subsystem: "com.deepseek.toolbox", category: "ProxyServer")

class ProxyServer {
    static let shared = ProxyServer()
    private var listener: NWListener?
    private(set) var port: UInt16 = 10080
    private(set) var isRunning = false
    private var connections: [NWConnection] = []
    private let queue = DispatchQueue(label: "com.deepseek.proxy", qos: .default)
    private let maxConnections = 50

    private let mitmEngine = MITMEngine.shared
    private let interceptor = TrafficIntercept.shared
    private var activeEndpoints: [String: Int] = [:]

    private init() {}

    func start(port: UInt16 = 10080) throws {
        guard !isRunning else { return }
        self.port = port
        let params = NWParameters.tcp
        params.allowLocalEndpointReuse = true
        params.requiredInterfaceType = .loopback
        params.prohibitedInterfaceTypes = [.cellular, .wifi, .wiredEthernet]
        guard let listener = try? NWListener(using: params, on: NWEndpoint.Port(rawValue: port)!) else {
            throw ProxyError.portInUse
        }
        listener.stateUpdateHandler = { [weak self] state in
            self?.handleListenerState(state)
        }
        listener.newConnectionHandler = { [weak self] connection in
            self?.handleNewConnection(connection)
        }
        listener.start(queue: queue)
        self.listener = listener
        isRunning = true
        os_log(.info, log: log, "Proxy started on 127.0.0.1:%d", port)
    }

    func stop() {
        guard isRunning else { return }
        listener?.cancel()
        listener = nil
        for conn in connections {
            conn.cancel()
        }
        connections.removeAll()
        isRunning = false
        os_log(.info, log: log, "Proxy stopped")
    }

    func status() -> (running: Bool, port: UInt16, endpoints: [String: Int]) {
        return (isRunning, port, activeEndpoints)
    }

    private func handleListenerState(_ state: NWListener.State) {
        switch state {
        case .failed(let error):
            os_log(.error, log: log, "Proxy listener failed: %{public}@", error.localizedDescription)
            isRunning = false
        case .ready:
            os_log(.info, log: log, "Proxy listener ready")
        default:
            break
        }
    }

    private func handleNewConnection(_ connection: NWConnection) {
        if connections.count >= maxConnections {
            connection.cancel()
            return
        }
        connections.append(connection)
        connection.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                self?.readInitialData(connection)
            case .failed, .cancelled:
                self?.connections.removeAll { $0 === connection }
            default:
                break
            }
        }
        connection.start(queue: queue)
    }

    private func readInitialData(_ clientConn: NWConnection) {
        clientConn.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, _, error in
            guard let self = self, let data = data, error == nil else {
                self?.connections.removeAll { $0 === clientConn }
                return
            }
            guard let headerStr = String(data: data, encoding: .utf8) else {
                clientConn.cancel()
                self.connections.removeAll { $0 === clientConn }
                return
            }
            let lines = headerStr.components(separatedBy: "\r\n")
            guard let firstLine = lines.first, !firstLine.isEmpty else {
                clientConn.cancel()
                self.connections.removeAll { $0 === clientConn }
                return
            }
            if firstLine.hasPrefix("CONNECT") {
                self.handleCONNECT(firstLine, remaining: data, clientConn: clientConn)
            } else {
                self.handleHTTP(firstLine, fullData: data, clientConn: clientConn)
            }
        }
    }

    private func handleHTTP(_ firstLine: String, fullData: Data, clientConn: NWConnection) {
        let parts = firstLine.components(separatedBy: " ")
        guard parts.count >= 2 else {
            clientConn.cancel(); connections.removeAll { $0 === clientConn }; return
        }
        let method = parts[0]
        let path = parts[1]
        let headers = parseHeaders(String(data: fullData, encoding: .utf8) ?? "")
        let host = headers["Host"] ?? ""
        _ = findBodyStart(fullData)

        interceptor.matchRequest(method: method, path: path, host: host)

        guard let targetHost = host.components(separatedBy: ":").first else {
            clientConn.cancel(); connections.removeAll { $0 === clientConn }; return
        }
        let targetPort: UInt16 = host.contains(":") ? UInt16(host.components(separatedBy: ":")[1]) ?? 80 : 80

        let targetConn = NWConnection(host: NWEndpoint.Host(targetHost),
                                       port: NWEndpoint.Port(rawValue: targetPort)!,
                                       using: .tcp)

        targetConn.stateUpdateHandler = { state in
            switch state {
            case .ready:
                let bytes = [UInt8](fullData)
                let sendData = Data(bytes)
                targetConn.send(content: sendData, completion: NWConnection.SendCompletion.contentProcessed({ _ in }))
                self.relayBidirectional(clientConn: clientConn, targetConn: targetConn,
                                        host: host, targetHost: targetHost)
            case .failed, .cancelled:
                clientConn.cancel()
                self.connections.removeAll { $0 === clientConn }
            default: break
            }
        }
        targetConn.start(queue: self.queue)
    }

    private func handleCONNECT(_ firstLine: String, remaining: Data, clientConn: NWConnection) {
        let parts = firstLine.components(separatedBy: " ")
        guard parts.count >= 2 else {
            clientConn.cancel(); connections.removeAll { $0 === clientConn }; return
        }
        let target = parts[1]
        let targetParts = target.components(separatedBy: ":")
        let targetHost = targetParts[0]
        let targetPort = targetParts.count > 1 ? UInt16(targetParts[1]) ?? 443 : 443

        let isAI = interceptor.isAITraffic(host: targetHost)
        let trackingHost = isAI ? targetHost : ""

        if isAI {
            mitmEngine.mitmConnect(clientConnection: clientConn,
                                    host: trackingHost,
                                    targetHost: targetHost,
                                    targetPort: targetPort) { [weak self] reqData, respData, reqHost in
                self?.interceptor.processTraffic(host: reqHost,
                                                  requestData: reqData,
                                                  responseData: respData)
            }
        } else {
            relayCONNECT(clientConn: clientConn, targetHost: targetHost, targetPort: targetPort)
        }
    }

    private func relayCONNECT(clientConn: NWConnection, targetHost: String, targetPort: UInt16) {
        let ok200 = "HTTP/1.1 200 Connection Established\r\n\r\n"
        clientConn.send(content: ok200.data(using: .utf8)!, completion: NWConnection.SendCompletion.contentProcessed({ _ in }))

        let targetConn = NWConnection(host: NWEndpoint.Host(targetHost),
                                       port: NWEndpoint.Port(rawValue: targetPort)!,
                                       using: .tcp)
        targetConn.stateUpdateHandler = { state in
            switch state {
            case .ready:
                self.relayRaw(clientConn: clientConn, targetConn: targetConn)
            case .failed, .cancelled:
                clientConn.cancel()
                self.connections.removeAll { $0 === clientConn }
            default: break
            }
        }
        connections.append(targetConn)
        targetConn.start(queue: self.queue)
    }

    private func relayBidirectional(clientConn: NWConnection, targetConn: NWConnection,
                                     host: String, targetHost: String) {
        connections.append(targetConn)

        func relay(from source: NWConnection, to destination: NWConnection, isResponse: Bool) {
            source.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, _, error in
                guard let self = self else { return }
                if let data = data, !data.isEmpty {
                    if isResponse, let host = host.components(separatedBy: ":").first,
                       self.interceptor.isAITraffic(host: host) {
                        self.interceptor.parseResponse(data: data, for: host)
                    }
                    destination.send(content: data, completion: NWConnection.SendCompletion.contentProcessed({ _ in }))
                    relay(from: source, to: destination, isResponse: isResponse)
                } else {
                    source.cancel()
                    destination.cancel()
                    self.connections.removeAll { $0 === source }
                    self.connections.removeAll { $0 === destination }
                }
            }
        }
        relay(from: clientConn, to: targetConn, isResponse: false)
        relay(from: targetConn, to: clientConn, isResponse: true)
    }

    private func relayRaw(clientConn: NWConnection, targetConn: NWConnection) {
        [clientConn, targetConn].forEach { $0.betterPathUpdateHandler = nil }
        relayRawDirection(from: clientConn, to: targetConn)
        relayRawDirection(from: targetConn, to: clientConn)
    }

    private func relayRawDirection(from source: NWConnection, to destination: NWConnection) {
        source.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, _, error in
            guard let self = self else { return }
            if let data = data, !data.isEmpty {
                destination.send(content: data, completion: NWConnection.SendCompletion.contentProcessed({ _ in }))
                self.relayRawDirection(from: source, to: destination)
            } else {
                source.cancel()
                destination.cancel()
                self.connections.removeAll { $0 === source }
                self.connections.removeAll { $0 === destination }
            }
        }
    }

    private func parseHeaders(_ raw: String) -> [String: String] {
        var headers: [String: String] = [:]
        for line in raw.components(separatedBy: "\r\n") {
            let colonParts = line.components(separatedBy: ": ")
            if colonParts.count >= 2 {
                headers[colonParts[0].lowercased()] = colonParts.dropFirst().joined(separator: ": ")
            }
        }
        return headers
    }

    private func findBodyStart(_ data: Data) -> Int {
        let crlfcrlf = Data([0x0D, 0x0A, 0x0D, 0x0A])
        if let range = data.range(of: crlfcrlf) {
            return range.upperBound
        }
        return data.count
    }

    func recordEndpoint(_ host: String) {
        activeEndpoints[host] = (activeEndpoints[host] ?? 0) + 1
    }
}

enum ProxyError: LocalizedError {
    case portInUse
    var errorDescription: String? {
        switch self {
        case .portInUse: return "端口已被占用，请尝试其他端口"
        }
    }
}
