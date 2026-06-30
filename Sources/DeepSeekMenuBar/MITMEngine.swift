import Foundation
import Network
import Security
import os.log

private let log2 = OSLog(subsystem: "com.deepseek.toolbox", category: "MITM")

class MITMEngine {
    static let shared = MITMEngine()
    private let queue = DispatchQueue(label: "com.deepseek.mitm", qos: .userInitiated)

    private var caSecKey: SecKey?
    private var caSecCert: SecCertificate?

    private init() {
        loadOrGenerateCA()
    }

    var caCertificateExists: Bool {
        return caSecCert != nil
    }

    func exportCACertificateData() -> Data? {
        guard let cert = caSecCert else { return nil }
        return SecCertificateCopyData(cert) as Data
    }

    func exportCACertificatePEM() -> String? {
        guard let data = exportCACertificateData() else { return nil }
        let base64 = data.base64EncodedString()
        var pem = "-----BEGIN CERTIFICATE-----\n"
        var i = base64.startIndex
        while i < base64.endIndex {
            let end = base64.index(i, offsetBy: 64, limitedBy: base64.endIndex) ?? base64.endIndex
            pem += base64[i..<end] + "\n"
            i = end
        }
        pem += "-----END CERTIFICATE-----\n"
        return pem
    }

    func mitmConnect(clientConnection: NWConnection, host: String,
                      targetHost: String, targetPort: UInt16,
                      onTraffic: @escaping (Data, Data, String) -> Void) {
        let ok200 = "HTTP/1.1 200 Connection Established\r\n\r\n"
        clientConnection.send(content: ok200.data(using: .utf8)!, completion: .contentProcessed({ _ in }))

        let targetConnection = NWConnection(host: NWEndpoint.Host(targetHost),
                                             port: NWEndpoint.Port(rawValue: targetPort)!,
                                             using: NWParameters.tls)
        targetConnection.stateUpdateHandler = { (state: NWConnection.State) in
            switch state {
            case .ready:
                self.relayAndCapture(client: clientConnection, target: targetConnection,
                                      host: host, onTraffic: onTraffic)
            case .failed:
                clientConnection.cancel()
            default: break
            }
        }
        targetConnection.start(queue: self.queue)

        clientConnection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { data, _, _, error in
            if let data = data, !data.isEmpty {
                targetConnection.send(content: data, completion: NWConnection.SendCompletion.contentProcessed({ _ in }))
            }
        }
    }

    private func relayAndCapture(client: NWConnection, target: NWConnection,
                                  host: String,
                                  onTraffic: @escaping (Data, Data, String) -> Void) {
        var requestBuffer = Data()
        var responseBuffer = Data()

        func readClient() {
            client.receive(minimumIncompleteLength: 1, maximumLength: 65536) { data, _, _, error in
                guard let data = data, !data.isEmpty else {
                    client.cancel()
                    return
                }
                requestBuffer.append(data)
                target.send(content: data, completion: .contentProcessed({ _ in }))
                readClient()
            }
        }

        func readTarget() {
            target.receive(minimumIncompleteLength: 1, maximumLength: 65536) { data, _, _, error in
                guard let data = data, !data.isEmpty else {
                    target.cancel()
                    client.cancel()
                    return
                }
                responseBuffer.append(data)
                client.send(content: data, completion: .contentProcessed({ _ in }))

                if let bodyRange = self.findHTTPBody(responseBuffer) {
                    let body = responseBuffer.subdata(in: bodyRange)
                    let requestBody = self.findHTTPBody(requestBuffer).map { requestBuffer.subdata(in: $0) } ?? Data()
                    if !body.isEmpty {
                        onTraffic(requestBody, body, host)
                    }
                    responseBuffer = Data()
                }
                readTarget()
            }
        }
        readClient()
        readTarget()
    }

    private func findHTTPBody(_ data: Data) -> Range<Int>? {
        guard let str = String(data: data, encoding: .utf8) else { return nil }
        if let range = str.range(of: "\r\n\r\n") {
            let pos = str.distance(from: str.startIndex, to: range.upperBound)
            if pos < data.count {
                return pos..<data.count
            }
        }
        return nil
    }

    private func createTLSOptions() -> NWProtocolTLS.Options {
        let tlsOptions = NWProtocolTLS.Options()
        sec_protocol_options_set_min_tls_protocol_version(tlsOptions.securityProtocolOptions, .TLSv12)
        sec_protocol_options_set_verify_block(tlsOptions.securityProtocolOptions, { _, _, complete in
            complete(true)
        }, queue)
        return tlsOptions
    }

    private func loadOrGenerateCA() {
        let tag = "com.deepseek.toolbox.ca".data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: tag,
            kSecReturnRef as String: true,
        ]
        var item: CFTypeRef?
        if SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess {
            caSecKey = (item as! SecKey)
            os_log(.info, log: log2, "Loaded existing CA key from Keychain")
            return
        }
        os_log(.info, log: log2, "Generating new CA certificate...")
        do {
            try generateCA()
        } catch {
            os_log(.error, log: log2, "Failed to generate CA: %{public}@", error.localizedDescription)
        }
    }

    private func generateCA() throws {
        let keyParams: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeySizeInBits as String: 2048,
        ]
        guard let privateKey = SecKeyCreateRandomKey(keyParams as CFDictionary, nil) else {
            throw NSError(domain: "MITM", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create CA private key"])
        }
        guard let publicKey = SecKeyCopyPublicKey(privateKey) else {
            throw NSError(domain: "MITM", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to get public key"])
        }
        let certData = try createSelfSignedCertificate(privateKey: privateKey, publicKey: publicKey)
        guard let certificate = SecCertificateCreateWithData(nil, certData as CFData) else {
            throw NSError(domain: "MITM", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to create certificate"])
        }
        let tag = "com.deepseek.toolbox.ca".data(using: .utf8)!
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecValueRef as String: privateKey,
            kSecAttrApplicationTag as String: tag,
            kSecAttrLabel as String: "DeepSeek工具箱 CA Key",
        ]
        SecItemAdd(addQuery as CFDictionary, nil)
        caSecKey = privateKey
        caSecCert = certificate
        os_log(.info, log: log2, "CA certificate generated successfully")
    }

    private func createSelfSignedCertificate(privateKey: SecKey, publicKey: SecKey) throws -> Data {
        let subjectName = "CN=DeepSeek工具箱 CA,O=AI Usage Tracker,C=CN"
        let derName = try subjectName.data(using: .utf8).map {
            try x509EncodeSubjectName($0)
        } ?? Data()

        let serialNumber = Data([0x01])
        let notBefore = Date()
        let notAfter = Calendar.current.date(byAdding: .year, value: 10, to: Date())!

        let pubKeyData = SecKeyCopyExternalRepresentation(publicKey, nil)! as Data
        let pubKeyInfo = wrapPublicKey(pubKeyData)

        let tbsBytes = try buildTBSCertificate(
            serial: serialNumber,
            issuer: derName,
            subject: derName,
            notBefore: notBefore,
            notAfter: notAfter,
            pubKeyInfo: pubKeyInfo)

        guard let signer = SecKeyCreateSignature(privateKey, .rsaSignatureMessagePKCS1v15SHA256, tbsBytes as CFData, nil) else {
            throw NSError(domain: "MITM", code: 4)
        }
        let signatureData = signer as Data
        let certBytes = tbsBytes + x509Tag(0x30, x509Tag(0x03, Data([0x00]) + x509Tag(0x30, algorithmIdentifier()) + Data([0x00]) + x509BitString(signatureData)))
        return x509Tag(0x30, certBytes)
    }

    private func buildTBSCertificate(serial: Data, issuer: Data, subject: Data,
                                      notBefore: Date, notAfter: Date,
                                      pubKeyInfo: Data) throws -> Data {
        let version = x509Tag(0xA0, Data([0x02, 0x01, 0x02]))
        let serialNum = Data([0x02]) + x509Length(serial.count) + serial
        let algoID = algorithmIdentifier()
        let issuerDN = x509Tag(0x30, issuer)
        let validity = x509Tag(0x30,
            x509EncodeTime(notBefore, isUTC: true) +
            x509EncodeTime(notAfter, isUTC: true))
        let subjectDN = x509Tag(0x30, subject)
        let pubKey = pubKeyInfo
        return version + serialNum + algoID + issuerDN + validity + subjectDN + pubKey
    }

    private func algorithmIdentifier() -> Data {
        let oid = Data([0x2A, 0x86, 0x48, 0x86, 0xF7, 0x0D, 0x01, 0x01, 0x0B])
        return x509Tag(0x30, x509Tag(0x06, oid) + Data([0x05, 0x00]))
    }

    private func wrapPublicKey(_ raw: Data) -> Data {
        let oid = Data([0x2A, 0x86, 0x48, 0x86, 0xF7, 0x0D, 0x01, 0x01, 0x01])
        let algo = x509Tag(0x30, x509Tag(0x06, oid) + Data([0x05, 0x00]))
        return x509Tag(0x30, algo + x509BitString(raw))
    }

    private func x509EncodeSubjectName(_ data: Data) throws -> Data {
        let components: [(String, String)] = [
            ("2.5.4.6", "CN"),
            ("2.5.4.10", "AI Usage Tracker"),
            ("2.5.4.3", "DeepSeek工具箱 CA"),
        ]
        var result = Data()
        for (oid, value) in components {
            let oidBytes = try encodeOID(oid)
            let oidTag = x509Tag(0x06, oidBytes)
            let utf8Bytes = value.data(using: .utf8)!
            let valTag = x509Tag(0x0C, utf8Bytes)
            let setTag = x509Tag(0x31, oidTag + valTag)
            result += setTag
        }
        return result
    }

    private func encodeOID(_ oid: String) throws -> Data {
        let parts = oid.components(separatedBy: ".")
        guard parts.count >= 2 else { throw NSError(domain: "MITM", code: 5) }
        var bytes = Data()
        let first = Int(parts[0])!
        let second = Int(parts[1])!
        bytes.append(UInt8(first * 40 + second))
        for partStr in parts.dropFirst(2) {
            guard let val = Int(partStr) else { throw NSError(domain: "MITM", code: 6) }
            if val < 128 {
                bytes.append(UInt8(val))
            } else {
                var stack: [UInt8] = []
                var v = val
                while v > 0 {
                    stack.insert(UInt8(v & 0x7F) | (stack.isEmpty ? 0 : 0x80), at: 0)
                    v >>= 7
                }
                bytes.append(contentsOf: stack)
            }
        }
        return bytes
    }

    private func x509Tag(_ tag: UInt8, _ data: Data) -> Data {
        var result = Data([tag])
        let len = data.count
        if len < 128 {
            result.append(UInt8(len))
        } else {
            var l = len
            var lenBytes: [UInt8] = []
            while l > 0 {
                lenBytes.insert(UInt8(l & 0xFF), at: 0)
                l >>= 8
            }
            result.append(UInt8(0x80 | lenBytes.count))
            result.append(contentsOf: lenBytes)
        }
        result.append(data)
        return result
    }

    private func x509Length(_ len: Int) -> Data {
        if len < 128 { return Data([UInt8(len)]) }
        var l = len
        var bytes: [UInt8] = []
        while l > 0 {
            bytes.insert(UInt8(l & 0xFF), at: 0)
            l >>= 8
        }
        return Data([UInt8(0x80 | bytes.count)]) + Data(bytes)
    }

    private func x509BitString(_ data: Data) -> Data {
        return Data([0x03]) + x509Length(data.count + 1) + Data([0x00]) + data
    }

    private func x509EncodeTime(_ date: Date, isUTC: Bool) -> Data {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "en_US_POSIX")
        fmt.dateFormat = isUTC ? "yyMMddHHmmss'Z'" : "yyyyMMddHHmmss'Z'"
        fmt.timeZone = TimeZone(secondsFromGMT: 0)
        let str = fmt.string(from: date)
        let tag: UInt8 = isUTC ? 0x17 : 0x18
        return x509Tag(tag, str.data(using: .ascii)!)
    }
}
