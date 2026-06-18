import Foundation

struct BalanceResponse: Codable {
    let balanceInfos: [BalanceInfo]

    enum CodingKeys: String, CodingKey {
        case balanceInfos = "balance_infos"
    }
}

struct BalanceInfo: Codable {
    let totalBalance: String
    let grantedBalance: String?
    let toppedUpBalance: String?

    enum CodingKeys: String, CodingKey {
        case totalBalance = "total_balance"
        case grantedBalance = "granted_balance"
        case toppedUpBalance = "topped_up_balance"
    }
}

struct UsageResponse: Codable {
    let id: String
    let object: String
    let created: Int
    let planUsage: PlanUsage

    enum CodingKeys: String, CodingKey {
        case id, object, created
        case planUsage = "plan_usage"
    }
}

struct PlanUsage: Codable {
    let totalTokens: Int
    let promptTokens: Int
    let completionTokens: Int

    enum CodingKeys: String, CodingKey {
        case totalTokens = "total_tokens"
        case promptTokens = "prompt_tokens"
        case completionTokens = "completion_tokens"
    }
}

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int, String)
    case networkError(Error)
    case decodingError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let code, let message):
            return "HTTP \(code): \(message)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Decoding error: \(error.localizedDescription)"
        }
    }
}

class APIClient {
    static let shared = APIClient()
    private let baseURL = "https://api.deepseek.com"
    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
    }

    func getBalance(apiKey: String) async throws -> BalanceResponse {
        guard let url = URL(string: "\(baseURL)/user/balance") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        try checkHTTPStatus(httpResponse, data: data)

        do {
            return try JSONDecoder().decode(BalanceResponse.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    func getUsage(apiKey: String) async throws -> UsageResponse {
        guard let url = URL(string: "\(baseURL)/user/usage") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        try checkHTTPStatus(httpResponse, data: data)

        do {
            return try JSONDecoder().decode(UsageResponse.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    private func checkHTTPStatus(_ response: HTTPURLResponse, data: Data) throws {
        let statusCode = response.statusCode
        let body = String(data: data, encoding: .utf8) ?? ""

        switch statusCode {
        case 200...299:
            return
        case 401:
            throw APIError.httpError(statusCode, "API key is invalid or expired")
        case 429:
            throw APIError.httpError(statusCode, "Rate limit exceeded. Please try again later")
        case 500...599:
            throw APIError.httpError(statusCode, "Server error: \(body)")
        default:
            throw APIError.httpError(statusCode, body)
        }
    }
}
