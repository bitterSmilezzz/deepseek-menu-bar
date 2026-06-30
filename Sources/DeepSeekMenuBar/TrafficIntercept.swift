import Foundation
import os.log

private let log3 = OSLog(subsystem: "com.deepseek.toolbox", category: "Intercept")

struct TrafficCapture {
    let host: String
    let method: String
    let path: String
    let model: String?
    let requestTokens: Int
    let responseTokens: Int
    let cacheHitTokens: Int
    let cacheMissTokens: Int
    let tool: String
}

class TrafficIntercept {
    static let shared = TrafficIntercept()

    private let pricing = ModelPricing.shared
    private let database = UsageDatabase.shared
    private let queue = DispatchQueue(label: "com.deepseek.traffic")

    static let aiEndpoints: Set<String> = [
        "api.openai.com",
        "api.anthropic.com",
        "api.deepseek.com",
        "api.moonshot.cn",
        "api.baichuan-ai.com",
        "open.bigmodel.cn",
        "api.minimax.chat",
        "dashscope.aliyuncs.com",
        "api.stepfun.com",
        "api.lingyiwanwu.com",
        "api.groq.com",
        "generativelanguage.googleapis.com",
        "api.mistral.ai",
        "api.cohere.com",
        "api.together.xyz",
        "api.fireworks.ai",
        "api.perplexity.ai",
        "api.x.ai",
        "api.anthropic.com",
        "api.deepseek.com",
        "api.openai.com",
    ]

    private var pending: [String: (model: String, requestTokenCount: Int)] = [:]

    func isAITraffic(host: String) -> Bool {
        for endpoint in Self.aiEndpoints {
            if host.contains(endpoint) || endpoint.contains(host) {
                return true
            }
        }
        return false
    }

    func matchRequest(method: String, path: String, host: String) {
        guard isAITraffic(host: host) else { return }
        let key = "\(host)\(path)"
        pending[key] = (model: "unknown", requestTokenCount: 0)
    }

    func processTraffic(host: String, requestData: Data, responseData: Data) {
        queue.async { [weak self] in
            self?.analyzeTraffic(host: host, requestData: requestData, responseData: responseData)
        }
    }

    func parseResponse(data: Data, for host: String) {
        queue.async { [weak self] in
            self?.tryExtractUsage(from: data, host: host)
        }
    }

    private func analyzeTraffic(host: String, requestData: Data, responseData: Data) {
        let model = extractModel(from: requestData)
        let requestTokens = requestData.isEmpty ? 0 : estimateTokens(from: requestData)
        let (responseTokens, cacheHit, cacheMiss) = extractUsage(from: responseData)

        guard responseTokens > 0 || requestTokens > 0 else { return }

        let provider = pricing.matchEndpoint(host) ?? "unknown"
        let tool = guessTool(from: host)

        let effectiveModel = model ?? "unknown"
        let reqTokens = max(requestTokens, cacheMiss)
        let respTokens = max(responseTokens, 1)

        database.appendRecord(
            tool: tool, provider: provider, model: effectiveModel,
            requestTokens: reqTokens, responseTokens: respTokens,
            cacheHitTokens: cacheHit, cacheMissTokens: cacheMiss,
            endpoint: "https://\(host)")

        os_log(.debug, log: log3, "Traffic: %{public}@ %{public}@ in=%d out=%d cache=%d",
               host, effectiveModel, reqTokens, respTokens, cacheHit)
        ProxyServer.shared.recordEndpoint(host)
    }

    private func tryExtractUsage(from data: Data, host: String) {
        let (responseTokens, cacheHit, cacheMiss) = extractUsage(from: data)
        guard responseTokens > 0 else { return }
        let key = pending.keys.first(where: { host.contains($0) || $0.contains(host) }) ?? ""
        let model = pending[key]?.model ?? "unknown"
        let provider = pricing.matchEndpoint(host) ?? "unknown"

        database.appendRecord(
            tool: guessTool(from: host), provider: provider, model: model,
            requestTokens: max(pending[key]?.requestTokenCount ?? 0, cacheMiss),
            responseTokens: responseTokens,
            cacheHitTokens: cacheHit, cacheMissTokens: cacheMiss,
            endpoint: "https://\(host)")

        pending[key] = nil
        ProxyServer.shared.recordEndpoint(host)
    }

    private func extractModel(from body: Data) -> String? {
        guard let json = try? JSONSerialization.jsonObject(with: body) as? [String: Any] else {
            return nil
        }
        if let model = json["model"] as? String {
            return model
        }
        return nil
    }

    private func extractUsage(from body: Data) -> (completion: Int, cacheHit: Int, cacheMiss: Int) {
        guard let json = try? JSONSerialization.jsonObject(with: body) as? [String: Any] else {
            return (0, 0, 0)
        }
        if let usage = json["usage"] as? [String: Any] {
            let completion = usage["completion_tokens"] as? Int ?? usage["output_tokens"] as? Int ?? 0
            let prompt = usage["prompt_tokens"] as? Int ?? usage["input_tokens"] as? Int ?? 0
            var cacheHit = 0
            if let details = usage["prompt_tokens_details"] as? [String: Any] {
                cacheHit = details["cached_tokens"] as? Int ?? 0
            }
            let cacheMiss = max(prompt - cacheHit, 0)
            return (completion, cacheHit, cacheMiss)
        }
        if let content = json["content"] as? [[String: Any]] {
            for block in content {
                if let text = block["text"] as? String {
                    return (text.count / 3, 0, 0)
                }
            }
        }
        if json["choices"] is [[String: Any]] || json["output"] != nil {
            return (body.count / 6, 0, 0)
        }
        return (0, 0, 0)
    }

    private func estimateTokens(from body: Data) -> Int {
        guard let str = String(data: body, encoding: .utf8) else { return 0 }
        if let json = try? JSONSerialization.jsonObject(with: body) as? [String: Any],
           let messages = json["messages"] as? [[String: Any]] {
            var total = 0
            for msg in messages {
                if let content = msg["content"] as? String {
                    total += content.count / 4
                } else if let content = msg["content"] as? [[String: Any]] {
                    for part in content {
                        if let text = part["text"] as? String {
                            total += text.count / 4
                        }
                    }
                }
            }
            return max(total, 1)
        }
        return max(str.count / 4, 1)
    }

    private func guessTool(from host: String) -> String {
        if host.contains("cursor") || host.contains("cursr") { return "Cursor" }
        if host.contains("github") || host.contains("copilot") { return "GitHub Copilot" }
        if host.contains("anthropic") { return "Claude" }
        if host.contains("openai") { return "ChatGPT/API" }
        if host.contains("deepseek") { return "DeepSeek" }
        if host.contains("moonshot") { return "Kimi" }
        if host.contains("zhipu") || host.contains("bigmodel") { return "智谱" }
        if host.contains("dashscope") { return "通义千问" }
        if host.contains("minimax") { return "MiniMax" }
        if host.contains("groq") { return "Groq" }
        if host.contains("mistral") { return "Mistral" }
        if host.contains("x.ai") { return "Grok" }
        if host.contains("google") { return "Gemini" }
        return "API"
    }
}
