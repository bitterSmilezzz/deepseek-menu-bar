import Foundation

struct UsageRecord: Codable, Identifiable {
    let id: String
    let timestamp: TimeInterval
    let tool: String
    let provider: String
    let model: String
    let requestTokens: Int
    let responseTokens: Int
    let cacheHitTokens: Int
    let cacheMissTokens: Int
    let costUSD: Double
    let costRMB: Double
    let endpoint: String
}

struct DailyStats: Codable {
    let date: String
    let totalRequests: Int
    let totalInputTokens: Int
    let totalOutputTokens: Int
    let totalCacheHitTokens: Int
    let totalCostUSD: Double
    let totalCostRMB: Double
    let modelBreakdown: [String: ModelStat]
}

struct ModelStat: Codable {
    var requests: Int
    var inputTokens: Int
    var outputTokens: Int
    var cacheHitTokens: Int
    var costUSD: Double
    var costRMB: Double
}

struct CostSummary: Codable {
    let totalCostUSD: Double
    let totalCostRMB: Double
    let totalTokens: Int
    let totalRequests: Int
}

class UsageDatabase {
    static let shared = UsageDatabase()
    private let dataDir: URL
    private let fileManager = FileManager.default
    private let dateFormatter: DateFormatter
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private var pendingRecords: [UsageRecord] = []
    private let writeQueue = DispatchQueue(label: "com.deepseek.usage-db", qos: .utility)

    private init() {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        dataDir = appSupport.appendingPathComponent("DeepSeek工具箱/data")
        try? fileManager.createDirectory(at: dataDir, withIntermediateDirectories: true)

        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")

        encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        decoder = JSONDecoder()
    }

    func appendRecord(tool: String, provider: String, model: String,
                      requestTokens: Int, responseTokens: Int,
                      cacheHitTokens: Int, cacheMissTokens: Int,
                      endpoint: String) {
        let recordId = "rec_\(Int(Date().timeIntervalSince1970 * 1000))_\(UUID().uuidString.prefix(6))"
        let pricing = ModelPricing.shared

        var resolvedProvider = provider
        if resolvedProvider.isEmpty || resolvedProvider == "unknown" {
            resolvedProvider = pricing.matchEndpoint(endpoint) ?? "unknown"
        }

        let costUSD = pricing.costUSD(
            inputTokens: requestTokens, outputTokens: responseTokens,
            cacheHitTokens: cacheHitTokens, model: model, provider: resolvedProvider)
        let costRMB = pricing.costRMB(
            inputTokens: requestTokens, outputTokens: responseTokens,
            cacheHitTokens: cacheHitTokens, model: model, provider: resolvedProvider)

        let record = UsageRecord(
            id: recordId, timestamp: Date().timeIntervalSince1970,
            tool: tool, provider: resolvedProvider, model: model,
            requestTokens: requestTokens, responseTokens: responseTokens,
            cacheHitTokens: cacheHitTokens, cacheMissTokens: cacheMissTokens,
            costUSD: costUSD, costRMB: costRMB, endpoint: endpoint)

        pendingRecords.append(record)
        flushIfNeeded()
    }

    private func flushIfNeeded() {
        if pendingRecords.count >= 10 {
            let batch = pendingRecords
            pendingRecords = []
            writeQueue.async { [weak self] in
                self?.flushBatch(batch)
            }
        }
    }

    func flush() {
        let batch = pendingRecords
        pendingRecords = []
        writeQueue.sync { [weak self] in
            self?.flushBatch(batch)
        }
    }

    private func flushBatch(_ batch: [UsageRecord]) {
        guard !batch.isEmpty else { return }
        let today = dateFormatter.string(from: Date())
        let fileURL = dataDir.appendingPathComponent("usage_\(today).json")

        var existing: [UsageRecord] = []
        if let data = try? Data(contentsOf: fileURL),
           let decoded = try? decoder.decode([UsageRecord].self, from: data) {
            existing = decoded
        }
        existing.append(contentsOf: batch)
        if let data = try? encoder.encode(existing) {
            try? data.write(to: fileURL)
        }
    }

    func todayStats() -> DailyStats {
        flush()
        let today = dateFormatter.string(from: Date())
        return statsFor(date: today)
    }

    func statsFor(date: String) -> DailyStats {
        let fileURL = dataDir.appendingPathComponent("usage_\(date).json")
        guard let data = try? Data(contentsOf: fileURL),
              let records = try? decoder.decode([UsageRecord].self, from: data) else {
            return DailyStats(date: date, totalRequests: 0, totalInputTokens: 0,
                            totalOutputTokens: 0, totalCacheHitTokens: 0,
                            totalCostUSD: 0, totalCostRMB: 0, modelBreakdown: [:])
        }
        return aggregate(records: records, date: date)
    }

    func recentStats(days: Int) -> [DailyStats] {
        flush()
        var result: [DailyStats] = []
        let cal = Calendar.current
        for i in 0..<days {
            let date = cal.date(byAdding: .day, value: -i, to: Date())!
            let dateStr = dateFormatter.string(from: date)
            result.append(statsFor(date: dateStr))
        }
        return result.reversed()
    }

    func costSummary(days: Int) -> CostSummary {
        let stats = recentStats(days: days)
        return CostSummary(
            totalCostUSD: stats.reduce(0) { $0 + $1.totalCostUSD },
            totalCostRMB: stats.reduce(0) { $0 + $1.totalCostRMB },
            totalTokens: stats.reduce(0) { $0 + $1.totalInputTokens + $1.totalOutputTokens },
            totalRequests: stats.reduce(0) { $0 + $1.totalRequests })
    }

    func allHistory(limit: Int = 500) -> [UsageRecord] {
        flush()
        var all: [UsageRecord] = []
        guard let files = try? fileManager.contentsOfDirectory(at: dataDir, includingPropertiesForKeys: nil) else {
            return []
        }
        for file in files.sorted(by: { $0.lastPathComponent > $1.lastPathComponent }) {
            guard file.lastPathComponent.hasPrefix("usage_"),
                  let data = try? Data(contentsOf: file),
                  let records = try? decoder.decode([UsageRecord].self, from: data) else { continue }
            all.append(contentsOf: records)
            if all.count >= limit { break }
        }
        return Array(all.prefix(limit))
    }

    private func aggregate(records: [UsageRecord], date: String) -> DailyStats {
        var modelBreakdown: [String: ModelStat] = [:]
        var totalInput = 0, totalOutput = 0, totalCache = 0
        var totalUSD = 0.0, totalRMB = 0.0

        for r in records {
            totalInput += r.requestTokens
            totalOutput += r.responseTokens
            totalCache += r.cacheHitTokens
            totalUSD += r.costUSD
            totalRMB += r.costRMB

            let key = "\(r.provider)/\(r.model)"
            var stat = modelBreakdown[key] ?? ModelStat(requests: 0, inputTokens: 0, outputTokens: 0, cacheHitTokens: 0, costUSD: 0, costRMB: 0)
            stat.requests += 1
            stat.inputTokens += r.requestTokens
            stat.outputTokens += r.responseTokens
            stat.cacheHitTokens += r.cacheHitTokens
            stat.costUSD += r.costUSD
            stat.costRMB += r.costRMB
            modelBreakdown[key] = stat
        }

        return DailyStats(date: date, totalRequests: records.count,
                         totalInputTokens: totalInput, totalOutputTokens: totalOutput,
                         totalCacheHitTokens: totalCache, totalCostUSD: totalUSD,
                         totalCostRMB: totalRMB, modelBreakdown: modelBreakdown)
    }
}
