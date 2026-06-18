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

export type Page = 'dashboard' | 'addkey' | 'tools' | 'news' | 'settings'

export interface BridgeResponse<T = any> {
  success: boolean
  data?: T
  error?: string
}
