export interface Balance {
  balance: number
  currency: string
  status: 'active' | 'low' | 'empty'
}

export interface Usage {
  inputTokens: number
  outputTokens: number
  totalTokens: number
  date: string
}

export interface Tool {
  id: string
  name: string
  description: string
  icon: string
  category: string
}

export interface ApiKey {
  id: string
  name: string
  key: string
  masked: string
  createdAt: string
  isActive: boolean
}

export interface NewsItem {
  id: string
  title: string
  source: string
  time: string
  url: string
  isNew?: boolean
}

export type Page = 'dashboard' | 'proxy' | 'stats' | 'pricing' | 'history' | 'addkey' | 'settings'

export interface UsageRecord {
  id: string
  timestamp: number
  tool: string
  provider: string
  model: string
  requestTokens: number
  responseTokens: number
  cacheHitTokens: number
  cacheMissTokens: number
  costUSD: number
  costRMB: number
  endpoint: string
}

export interface ModelStat {
  requests: number
  inputTokens: number
  outputTokens: number
  cacheHitTokens: number
  costUSD: number
  costRMB: number
}

export interface DailyStats {
  date: string
  totalRequests: number
  totalInputTokens: number
  totalOutputTokens: number
  totalCacheHitTokens: number
  totalCostUSD: number
  totalCostRMB: number
  modelBreakdown: Record<string, ModelStat>
}

export interface CostSummary {
  totalCostUSD: number
  totalCostRMB: number
  totalTokens: number
  totalRequests: number
}

export interface ModelPrice {
  input: number
  output: number
  cacheHit?: number
}

export type ProviderPrices = Record<string, Record<string, ModelPrice>>

export interface ProxyStatus {
  running: boolean
  port: number
  caInstalled: boolean
}

export interface BridgeResponse<T = any> {
  success: boolean
  data?: T
  error?: string
}

export interface DailyTrendPoint {
  date: string
  tokens: number
  costUSD: number
  costRMB: number
  requests: number
}
