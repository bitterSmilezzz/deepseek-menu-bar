import Foundation

struct ModelEntry {
    let provider: String
    let model: String
    let price: ModelPrice
}

struct ModelPrice: Codable {
    let input: Double
    let output: Double
    let cacheHit: Double?

    init(input: Double, output: Double, cacheHit: Double? = nil) {
        self.input = input
        self.output = output
        self.cacheHit = cacheHit
    }

    enum CodingKeys: String, CodingKey {
        case input, output, cacheHit = "cache_read"
    }
}

class ModelPricing {
    static let shared = ModelPricing()
    private(set) var providers: [String: [String: ModelPrice]] = [:]
    private let usdToRmbRate: Double = 7.25

    private init() {
        loadBuiltinPricing()
    }

    func priceFor(model: String, provider: String) -> ModelPrice? {
        return providers[provider]?[model]
    }

    func allModels() -> [ModelEntry] {
        var result: [ModelEntry] = []
        for (provider, models) in providers {
            for (model, price) in models {
                result.append(ModelEntry(provider: provider, model: model, price: price))
            }
        }
        result.sort { $0.provider < $1.provider || ($0.provider == $1.provider && $0.model < $1.model) }
        return result
    }

    func costUSD(inputTokens: Int, outputTokens: Int, cacheHitTokens: Int, model: String, provider: String) -> Double {
        guard let price = priceFor(model: model, provider: provider) else { return 0 }
        let inputM = Double(inputTokens) / 1_000_000.0
        let outputM = Double(outputTokens) / 1_000_000.0
        let cacheM = Double(cacheHitTokens) / 1_000_000.0
        let effectiveCachePrice = price.cacheHit ?? price.input
        return (inputM - cacheM) * price.input + outputM * price.output + cacheM * effectiveCachePrice
    }

    func costRMB(inputTokens: Int, outputTokens: Int, cacheHitTokens: Int, model: String, provider: String) -> Double {
        return costUSD(inputTokens: inputTokens, outputTokens: outputTokens, cacheHitTokens: cacheHitTokens, model: model, provider: provider) * usdToRmbRate
    }

    func matchEndpoint(_ host: String) -> String? {
        let mappings: [String: String] = [
            "api.openai.com": "openai",
            "api.anthropic.com": "anthropic",
            "api.deepseek.com": "deepseek",
            "api.moonshot.cn": "moonshot",
            "api.minimax.chat": "minimax",
            "api.baichuan-ai.com": "baichuan",
            "open.bigmodel.cn": "zhipu",
            "dashscope.aliyuncs.com": "qwen",
            "api.stepfun.com": "stepfun",
            "api.lingyiwanwu.com": "01ai",
            "api.groq.com": "groq",
            "generativelanguage.googleapis.com": "google",
            "api.mistral.ai": "mistral",
            "api.cohere.com": "cohere",
            "api.together.xyz": "together",
            "api.fireworks.ai": "fireworks",
            "api.perplexity.ai": "perplexity",
            "api.x.ai": "xai",
        ]
        for (endpoint, provider) in mappings {
            if host.contains(endpoint) { return provider }
        }
        for key in mappings.keys {
            if key.contains(host) { return mappings[key] }
        }
        return nil
    }

    private func loadBuiltinPricing() {
        providers["openai"] = [
            "gpt-4o": ModelPrice(input: 2.50, output: 10.00, cacheHit: 1.25),
            "gpt-4o-mini": ModelPrice(input: 0.15, output: 0.60, cacheHit: 0.075),
            "gpt-4-turbo": ModelPrice(input: 10.00, output: 30.00),
            "gpt-4": ModelPrice(input: 30.00, output: 60.00),
            "gpt-3.5-turbo": ModelPrice(input: 0.50, output: 1.50),
            "o1": ModelPrice(input: 15.00, output: 60.00),
            "o1-mini": ModelPrice(input: 3.00, output: 12.00),
            "o3-mini": ModelPrice(input: 1.10, output: 4.40),
            "o3": ModelPrice(input: 10.00, output: 40.00),
            "gpt-4.1": ModelPrice(input: 2.00, output: 8.00, cacheHit: 0.50),
            "gpt-4.1-mini": ModelPrice(input: 0.40, output: 1.60, cacheHit: 0.10),
            "gpt-4.1-nano": ModelPrice(input: 0.10, output: 0.40, cacheHit: 0.025),
        ]
        providers["anthropic"] = [
            "claude-opus-4-20250514": ModelPrice(input: 15.00, output: 75.00, cacheHit: 1.50),
            "claude-sonnet-4-20250514": ModelPrice(input: 3.00, output: 15.00, cacheHit: 0.30),
            "claude-3.5-sonnet": ModelPrice(input: 3.00, output: 15.00, cacheHit: 0.30),
            "claude-3.5-haiku": ModelPrice(input: 0.80, output: 4.00, cacheHit: 0.08),
            "claude-3-opus": ModelPrice(input: 15.00, output: 75.00),
            "claude-3-haiku": ModelPrice(input: 0.25, output: 1.25),
        ]
        providers["deepseek"] = [
            "deepseek-chat": ModelPrice(input: 0.27, output: 1.10, cacheHit: 0.07),
            "deepseek-reasoner": ModelPrice(input: 0.55, output: 2.19),
        ]
        providers["moonshot"] = [
            "moonshot-v1-8k": ModelPrice(input: 0.24, output: 0.24),
            "moonshot-v1-32k": ModelPrice(input: 0.72, output: 0.72),
            "moonshot-v1-128k": ModelPrice(input: 0.96, output: 0.96),
        ]
        providers["zhipu"] = [
            "glm-4-plus": ModelPrice(input: 0.50, output: 0.50),
            "glm-4": ModelPrice(input: 0.20, output: 0.20),
            "glm-4-air": ModelPrice(input: 0.014, output: 0.014),
            "glm-4-flash": ModelPrice(input: 0, output: 0),
            "glm-4-long": ModelPrice(input: 0.20, output: 0.20),
        ]
        providers["qwen"] = [
            "qwen-max": ModelPrice(input: 2.00, output: 6.00),
            "qwen-plus": ModelPrice(input: 0.80, output: 2.00),
            "qwen-turbo": ModelPrice(input: 0.30, output: 0.60),
            "qwen-long": ModelPrice(input: 0.50, output: 2.00),
        ]
        providers["minimax"] = [
            "abab6.5s": ModelPrice(input: 0.10, output: 0.10),
            "abab6.5": ModelPrice(input: 0.30, output: 0.30),
            "abab6": ModelPrice(input: 0.50, output: 0.50),
        ]
        providers["baichuan"] = [
            "Baichuan4": ModelPrice(input: 2.00, output: 4.00),
            "Baichuan3-Turbo": ModelPrice(input: 0.18, output: 0.18),
            "Baichuan2-Turbo": ModelPrice(input: 0.12, output: 0.12),
        ]
        providers["stepfun"] = [
            "step-1v": ModelPrice(input: 0.50, output: 2.00),
            "step-1": ModelPrice(input: 0.14, output: 0.28),
        ]
        providers["01ai"] = [
            "yi-large": ModelPrice(input: 0.28, output: 0.28),
            "yi-medium": ModelPrice(input: 0.04, output: 0.04),
            "yi-lightning": ModelPrice(input: 0.014, output: 0.014),
        ]
        providers["google"] = [
            "gemini-2.0-flash": ModelPrice(input: 0.10, output: 0.40),
            "gemini-2.0-pro": ModelPrice(input: 1.25, output: 10.00),
            "gemini-1.5-pro": ModelPrice(input: 1.25, output: 5.00),
            "gemini-1.5-flash": ModelPrice(input: 0.075, output: 0.30),
        ]
        providers["groq"] = [
            "llama-3.3-70b": ModelPrice(input: 0.59, output: 0.79),
            "llama-3.1-8b": ModelPrice(input: 0.05, output: 0.08),
            "mixtral-8x7b": ModelPrice(input: 0.24, output: 0.24),
            "gemma2-9b": ModelPrice(input: 0.20, output: 0.20),
        ]
        providers["mistral"] = [
            "mistral-large": ModelPrice(input: 2.00, output: 6.00),
            "mistral-medium": ModelPrice(input: 2.70, output: 8.10),
            "mistral-small": ModelPrice(input: 1.00, output: 3.00),
            "codestral": ModelPrice(input: 1.00, output: 3.00),
        ]
        providers["cohere"] = [
            "command-r-plus": ModelPrice(input: 2.50, output: 10.00),
            "command-r": ModelPrice(input: 0.50, output: 1.50),
        ]
        providers["together"] = [
            "llama-3.1-405b": ModelPrice(input: 2.50, output: 2.50),
            "llama-3.1-70b": ModelPrice(input: 0.90, output: 0.90),
            "llama-3.1-8b": ModelPrice(input: 0.18, output: 0.18),
            "mixtral-8x22b": ModelPrice(input: 1.20, output: 1.20),
        ]
        providers["fireworks"] = [
            "llama-v3p1-405b": ModelPrice(input: 3.00, output: 3.00),
            "llama-v3p1-70b": ModelPrice(input: 0.90, output: 0.90),
            "llama-v3p1-8b": ModelPrice(input: 0.20, output: 0.20),
            "mixtral-8x22b": ModelPrice(input: 0.90, output: 0.90),
        ]
        providers["perplexity"] = [
            "sonar-pro": ModelPrice(input: 3.00, output: 15.00),
            "sonar": ModelPrice(input: 1.00, output: 1.00),
        ]
        providers["xai"] = [
            "grok-2": ModelPrice(input: 2.00, output: 10.00),
            "grok-beta": ModelPrice(input: 5.00, output: 15.00),
        ]
    }
}
