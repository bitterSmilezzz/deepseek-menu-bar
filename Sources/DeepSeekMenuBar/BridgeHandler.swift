import Foundation
import WebKit

enum BridgeMethod: String {
    case getBalance
    case getUsage
    case getTools
    case searchNews
    case getApiKeys
    case saveApiKey
    case deleteApiKey
    case setActiveKey
    case togglePin
    case quitApp
    case toggleWindow
    case startProxy
    case stopProxy
    case getProxyStatus
    case getUsageRecords
    case getTodayStats
    case getRecentStats
    case getCostSummary
    case getAllPrices
    case getHistory
}

struct BridgeRequest: Codable {
    let method: String
    let params: [String: AnyCodable]?
    let requestId: String?

    enum CodingKeys: String, CodingKey {
        case method, params
        case requestId = "request_id"
    }
}

struct AnyCodable: Codable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let string = try? container.decode(String.self) {
            value = string
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array
        } else {
            value = ""
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let string = value as? String {
            try container.encode(string)
        } else if let int = value as? Int {
            try container.encode(int)
        } else if let double = value as? Double {
            try container.encode(double)
        } else if let bool = value as? Bool {
            try container.encode(bool)
        } else if let dict = value as? [String: Any] {
            let wrapped = dict.mapValues { AnyCodable($0) }
            try container.encode(wrapped)
        } else if let array = value as? [Any] {
            let wrapped = array.map { AnyCodable($0) }
            try container.encode(wrapped)
        }
    }
}

struct NewsItem: Codable {
    let title: String
    let url: String
    let source: String
    let date: String
    let summary: String
}

class BridgeHandler: NSObject, WKScriptMessageHandler {
    weak var popoverController: PopoverController?
    private var activeKeyId: String?

    func setActiveKeyId(_ id: String?) {
        activeKeyId = id
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "bridge",
              let body = message.body as? [String: Any] else {
            return
        }

        guard let methodString = body["method"] as? String,
              let method = BridgeMethod(rawValue: methodString) else {
            sendError(requestId: body["request_id"] as? String, webView: message.webView, error: "Unknown method: \(body["method"] ?? "")")
            return
        }

        let params = body["params"] as? [String: Any]
        let requestId = body["request_id"] as? String

        Task {
            await handleMethod(method, params: params, requestId: requestId, webView: message.webView)
        }
    }

    private func handleMethod(_ method: BridgeMethod, params: [String: Any]?, requestId: String?, webView: WKWebView?) async {
        switch method {
        case .getBalance:
            await handleGetBalance(requestId: requestId, webView: webView)
        case .getUsage:
            await handleGetUsage(requestId: requestId, webView: webView)
        case .getTools:
            handleGetTools(requestId: requestId, webView: webView)
        case .searchNews:
            let query = params?["query"] as? String ?? ""
            await handleSearchNews(query: query, requestId: requestId, webView: webView)
        case .getApiKeys:
            handleGetApiKeys(requestId: requestId, webView: webView)
        case .saveApiKey:
            let name = params?["name"] as? String ?? ""
            let key = params?["key"] as? String ?? ""
            handleSaveApiKey(name: name, key: key, requestId: requestId, webView: webView)
        case .deleteApiKey:
            let id = params?["id"] as? String ?? ""
            handleDeleteApiKey(id: id, requestId: requestId, webView: webView)
        case .setActiveKey:
            let id = params?["id"] as? String
            handleSetActiveKey(id: id, requestId: requestId, webView: webView)
        case .togglePin:
            handleTogglePin(requestId: requestId, webView: webView)
        case .quitApp:
            handleQuitApp(requestId: requestId, webView: webView)
        case .toggleWindow:
            handleToggleWindow(requestId: requestId, webView: webView)
        case .startProxy:
            handleStartProxy(requestId: requestId, webView: webView)
        case .stopProxy:
            handleStopProxy(requestId: requestId, webView: webView)
        case .getProxyStatus:
            handleGetProxyStatus(requestId: requestId, webView: webView)
        case .getUsageRecords:
            handleGetUsageRecords(requestId: requestId, webView: webView)
        case .getTodayStats:
            handleGetTodayStats(requestId: requestId, webView: webView)
        case .getRecentStats:
            handleGetRecentStats(requestId: requestId, webView: webView)
        case .getCostSummary:
            handleGetCostSummary(requestId: requestId, webView: webView)
        case .getAllPrices:
            handleGetAllPrices(requestId: requestId, webView: webView)
        case .getHistory:
            handleGetHistory(requestId: requestId, webView: webView)
        }
    }

    private func handleGetBalance(requestId: String?, webView: WKWebView?) async {
        do {
            let keys = try KeychainManager.shared.loadAll()
            guard let activeKey = getActiveKey(from: keys) else {
                sendResult(requestId: requestId, webView: webView, data: ["error": "No active API key"])
                return
            }
            let response = try await APIClient.shared.getBalance(apiKey: activeKey.key)
            let balance = response.balanceInfos.first
            sendResult(requestId: requestId, webView: webView, data: [
                "total_balance": balance?.totalBalance ?? "0",
                "granted_balance": balance?.grantedBalance ?? "0",
                "topped_up_balance": balance?.toppedUpBalance ?? "0"
            ])
        } catch {
            sendError(requestId: requestId, webView: webView, error: error.localizedDescription)
        }
    }

    private func handleGetUsage(requestId: String?, webView: WKWebView?) async {
        do {
            let keys = try KeychainManager.shared.loadAll()
            guard let activeKey = getActiveKey(from: keys) else {
                sendResult(requestId: requestId, webView: webView, data: ["error": "No active API key"])
                return
            }
            let response = try await APIClient.shared.getUsage(apiKey: activeKey.key)
            sendResult(requestId: requestId, webView: webView, data: [
                "total_tokens": response.planUsage.totalTokens,
                "prompt_tokens": response.planUsage.promptTokens,
                "completion_tokens": response.planUsage.completionTokens
            ] as [String: Any])
        } catch {
            sendError(requestId: requestId, webView: webView, error: error.localizedDescription)
        }
    }

    private func handleGetTools(requestId: String?, webView: WKWebView?) {
        let tools = [
            ["id": "balance", "name": "Balance Check", "icon": "dollarsign.circle", "description": "Check your DeepSeek API account balance"],
            ["id": "usage", "name": "Usage Stats", "icon": "chart.bar", "description": "View today's token usage statistics"],
            ["id": "search", "name": "News Search", "icon": "magnifyingglass", "description": "Search for latest AI and tech news"],
            ["id": "settings", "name": "Settings", "icon": "gear", "description": "Manage API keys and application settings"]
        ]
        sendResult(requestId: requestId, webView: webView, data: ["tools": tools])
    }

    private func handleSearchNews(query: String, requestId: String?, webView: WKWebView?) async {
        let searchURLString = "https://api.duckduckgo.com/?q=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&format=json&no_html=1"

        guard let url = URL(string: searchURLString) else {
            sendResult(requestId: requestId, webView: webView, data: ["results": []])
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let abstract = json["Abstract"] as? String,
               let source = json["Source"] as? String {
                let results: [[String: String]] = [
                    ["title": abstract, "url": json["AbstractURL"] as? String ?? "", "source": source, "date": "", "summary": abstract]
                ].filter { $0["title"]?.isEmpty == false }
                sendResult(requestId: requestId, webView: webView, data: ["results": results])
            } else {
                sendResult(requestId: requestId, webView: webView, data: ["results": []])
            }
        } catch {
            sendResult(requestId: requestId, webView: webView, data: ["results": []])
        }
    }

    private func handleGetApiKeys(requestId: String?, webView: WKWebView?) {
        do {
            let keys = try KeychainManager.shared.loadAll()
            let keyList = keys.map { key -> [String: Any] in
                [
                    "id": key.id,
                    "name": key.name,
                    "key": key.key,
                    "created_at": ISO8601DateFormatter().string(from: key.createdAt),
                    "is_active": key.id == activeKeyId
                ]
            }
            sendResult(requestId: requestId, webView: webView, data: ["keys": keyList, "active_key_id": activeKeyId as Any])
        } catch {
            sendError(requestId: requestId, webView: webView, error: error.localizedDescription)
        }
    }

    private func handleSaveApiKey(name: String, key: String, requestId: String?, webView: WKWebView?) {
        let storedKey = StoredKey(
            id: UUID().uuidString,
            name: name,
            key: key,
            createdAt: Date()
        )

        do {
            try KeychainManager.shared.save(key: storedKey)
            if activeKeyId == nil {
                activeKeyId = storedKey.id
            }
            sendResult(requestId: requestId, webView: webView, data: [
                "id": storedKey.id,
                "name": storedKey.name,
                "created_at": ISO8601DateFormatter().string(from: storedKey.createdAt)
            ])
        } catch {
            sendError(requestId: requestId, webView: webView, error: error.localizedDescription)
        }
    }

    private func handleDeleteApiKey(id: String, requestId: String?, webView: WKWebView?) {
        do {
            try KeychainManager.shared.delete(id: id)
            if activeKeyId == id {
                activeKeyId = nil
            }
            sendResult(requestId: requestId, webView: webView, data: ["success": true])
        } catch {
            sendError(requestId: requestId, webView: webView, error: error.localizedDescription)
        }
    }

    private func handleSetActiveKey(id: String?, requestId: String?, webView: WKWebView?) {
        activeKeyId = id
        NotificationCenter.default.post(name: NSNotification.Name("ActiveKeyChanged"), object: id)
        sendResult(requestId: requestId, webView: webView, data: ["success": true])
    }

    private func handleTogglePin(requestId: String?, webView: WKWebView?) {
        popoverController?.togglePin()
        sendResult(requestId: requestId, webView: webView, data: ["success": true])
    }

    private func handleQuitApp(requestId: String?, webView: WKWebView?) {
        sendResult(requestId: requestId, webView: webView, data: ["success": true])
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            NSApplication.shared.terminate(nil)
        }
    }

    private func handleToggleWindow(requestId: String?, webView: WKWebView?) {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: NSNotification.Name("ToggleWindow"), object: nil)
        }
        sendResult(requestId: requestId, webView: webView, data: ["success": true])
    }

    private func handleStartProxy(requestId: String?, webView: WKWebView?) {
        do {
            try ProxyServer.shared.start()
            sendResult(requestId: requestId, webView: webView, data: ["port": Int(ProxyServer.shared.port)])
        } catch {
            sendError(requestId: requestId, webView: webView, error: error.localizedDescription)
        }
    }

    private func handleStopProxy(requestId: String?, webView: WKWebView?) {
        ProxyServer.shared.stop()
        sendResult(requestId: requestId, webView: webView, data: ["success": true])
    }

    private func handleGetProxyStatus(requestId: String?, webView: WKWebView?) {
        let status = ProxyServer.shared.status()
        sendResult(requestId: requestId, webView: webView, data: [
            "running": status.running,
            "port": Int(status.port),
            "caInstalled": MITMEngine.shared.caCertificateExists
        ])
    }

    private func handleGetUsageRecords(requestId: String?, webView: WKWebView?) {
        let stats = UsageDatabase.shared.todayStats()
        sendResult(requestId: requestId, webView: webView, data: [
            "date": stats.date,
            "totalRequests": stats.totalRequests,
            "totalInputTokens": stats.totalInputTokens,
            "totalOutputTokens": stats.totalOutputTokens,
            "totalCacheHitTokens": stats.totalCacheHitTokens,
            "totalCostUSD": stats.totalCostUSD,
            "totalCostRMB": stats.totalCostRMB,
            "modelBreakdown": stats.modelBreakdown.mapValues { [
                "requests": $0.requests,
                "inputTokens": $0.inputTokens,
                "outputTokens": $0.outputTokens,
                "cacheHitTokens": $0.cacheHitTokens,
                "costUSD": $0.costUSD,
                "costRMB": $0.costRMB
            ] }
        ])
    }

    private func handleGetTodayStats(requestId: String?, webView: WKWebView?) {
        let stats = UsageDatabase.shared.todayStats()
        sendResult(requestId: requestId, webView: webView, data: [
            "date": stats.date,
            "totalRequests": stats.totalRequests,
            "totalInputTokens": stats.totalInputTokens,
            "totalOutputTokens": stats.totalOutputTokens,
            "totalCacheHitTokens": stats.totalCacheHitTokens,
            "totalCostUSD": stats.totalCostUSD,
            "totalCostRMB": stats.totalCostRMB,
            "modelBreakdown": stats.modelBreakdown.mapValues { [
                "requests": $0.requests,
                "inputTokens": $0.inputTokens,
                "outputTokens": $0.outputTokens,
                "cacheHitTokens": $0.cacheHitTokens,
                "costUSD": $0.costUSD,
                "costRMB": $0.costRMB
            ] }
        ])
    }

    private func handleGetRecentStats(requestId: String?, webView: WKWebView?) {
        let stats = UsageDatabase.shared.recentStats(days: 7)
        let data = stats.map { s -> [String: Any] in
            [
                "date": s.date,
                "totalRequests": s.totalRequests,
                "totalInputTokens": s.totalInputTokens,
                "totalOutputTokens": s.totalOutputTokens,
                "totalCacheHitTokens": s.totalCacheHitTokens,
                "totalCostUSD": s.totalCostUSD,
                "totalCostRMB": s.totalCostRMB,
                "modelBreakdown": [:] as [String: Any]
            ]
        }
        sendResult(requestId: requestId, webView: webView, data: ["stats": data])
    }

    private func handleGetCostSummary(requestId: String?, webView: WKWebView?) {
        let summary = UsageDatabase.shared.costSummary(days: 7)
        sendResult(requestId: requestId, webView: webView, data: [
            "totalCostUSD": summary.totalCostUSD,
            "totalCostRMB": summary.totalCostRMB,
            "totalTokens": summary.totalTokens,
            "totalRequests": summary.totalRequests
        ])
    }

    private func handleGetAllPrices(requestId: String?, webView: WKWebView?) {
        let models = ModelPricing.shared.allModels()
        var pricesByProvider: [String: [String: [String: Any]]] = [:]
        for entry in models {
            var priceDict: [String: Any] = [
                "input": entry.price.input,
                "output": entry.price.output
            ]
            if let cacheHit = entry.price.cacheHit {
                priceDict["cacheHit"] = cacheHit
            }
            if pricesByProvider[entry.provider] == nil {
                pricesByProvider[entry.provider] = [:]
            }
            pricesByProvider[entry.provider]?[entry.model] = priceDict
        }
        sendResult(requestId: requestId, webView: webView, data: ["prices": pricesByProvider])
    }

    private func handleGetHistory(requestId: String?, webView: WKWebView?) {
        let records = UsageDatabase.shared.allHistory(limit: 200)
        let data = records.map { r -> [String: Any] in
            [
                "id": r.id,
                "timestamp": r.timestamp,
                "tool": r.tool,
                "provider": r.provider,
                "model": r.model,
                "requestTokens": r.requestTokens,
                "responseTokens": r.responseTokens,
                "cacheHitTokens": r.cacheHitTokens,
                "cacheMissTokens": r.cacheMissTokens,
                "costUSD": r.costUSD,
                "costRMB": r.costRMB,
                "endpoint": r.endpoint
            ]
        }
        sendResult(requestId: requestId, webView: webView, data: ["records": data])
    }

    private func getActiveKey(from keys: [StoredKey]) -> StoredKey? {
        if let activeId = activeKeyId {
            return keys.first { $0.id == activeId }
        }
        return keys.first
    }

    private func sendResult(requestId: String?, webView: WKWebView?, data: [String: Any]) {
        var response: [String: Any] = [
            "type": "result",
            "data": data
        ]
        if let requestId = requestId {
            response["request_id"] = requestId
        }
        sendToWebView(webView, response: response)
    }

    private func sendError(requestId: String?, webView: WKWebView?, error: String) {
        var response: [String: Any] = [
            "type": "error",
            "error": error
        ]
        if let requestId = requestId {
            response["request_id"] = requestId
        }
        sendToWebView(webView, response: response)
    }

    private func sendToWebView(_ webView: WKWebView?, response: [String: Any]) {
        guard let webView = webView,
              let jsonData = try? JSONSerialization.data(withJSONObject: response),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return
        }

        let js = "window.__bridgeCallback(\(jsonString))"

        DispatchQueue.main.async {
            webView.evaluateJavaScript(js) { _, error in
                if let error = error {
                    print("Bridge eval error: \(error.localizedDescription)")
                }
            }
        }
    }
}
