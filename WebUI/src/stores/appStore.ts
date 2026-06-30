import { create } from 'zustand'
import type { Balance, Usage, Tool, ApiKey, NewsItem, Page, DailyStats, UsageRecord, CostSummary, ProviderPrices, ProxyStatus } from '../types'

interface AppState {
  currentPage: Page
  setPage: (page: Page) => void

  theme: 'dark' | 'light'
  toggleTheme: () => void
  setTheme: (theme: 'dark' | 'light') => void

  balance: Balance | null
  setBalance: (balance: Balance) => void

  usage: Usage | null
  setUsage: (usage: Usage) => void

  apiKeys: ApiKey[]
  setApiKeys: (keys: ApiKey[]) => void
  activeKeyId: string | null
  setActiveKeyId: (id: string | null) => void

  tools: Tool[]
  setTools: (tools: Tool[]) => void

  news: NewsItem[]
  setNews: (news: NewsItem[]) => void
  newsQuery: string
  setNewsQuery: (query: string) => void

  isPinned: boolean
  setPinned: (pinned: boolean) => void

  loading: boolean
  setLoading: (loading: boolean) => void
  error: string | null
  setError: (error: string | null) => void

  proxyStatus: ProxyStatus
  setProxyStatus: (status: ProxyStatus) => void

  todayStats: DailyStats | null
  setTodayStats: (stats: DailyStats | null) => void

  recentStats: DailyStats[]
  setRecentStats: (stats: DailyStats[]) => void

  usageRecords: UsageRecord[]
  setUsageRecords: (records: UsageRecord[]) => void

  costSummary: CostSummary | null
  setCostSummary: (summary: CostSummary | null) => void

  modelPrices: ProviderPrices | null
  setModelPrices: (prices: ProviderPrices | null) => void

  isWindowVisible: boolean
  setWindowVisible: (visible: boolean) => void
  toggleWindow: () => void
}

export const useAppStore = create<AppState>((set) => ({
  currentPage: 'dashboard',
  setPage: (page) => set({ currentPage: page }),

  theme: 'dark',
  toggleTheme: () => set((s) => ({ theme: s.theme === 'dark' ? 'light' : 'dark' })),
  setTheme: (theme) => set({ theme }),

  balance: null,
  setBalance: (balance) => set({ balance }),

  usage: null,
  setUsage: (usage) => set({ usage }),

  apiKeys: [],
  setApiKeys: (keys) => set({ apiKeys: keys }),
  activeKeyId: null,
  setActiveKeyId: (id) => set({ activeKeyId: id }),

  tools: [],
  setTools: (tools) => set({ tools }),

  news: [],
  setNews: (news) => set({ news }),
  newsQuery: '',
  setNewsQuery: (query) => set({ newsQuery: query }),

  isPinned: false,
  setPinned: (pinned) => set({ isPinned: pinned }),

  loading: false,
  setLoading: (loading) => set({ loading }),
  error: null,
  setError: (error) => set({ error }),

  proxyStatus: { running: false, port: 10080, caInstalled: false },
  setProxyStatus: (status) => set({ proxyStatus: status }),

  todayStats: null,
  setTodayStats: (stats) => set({ todayStats: stats }),

  recentStats: [],
  setRecentStats: (stats) => set({ recentStats: stats }),

  usageRecords: [],
  setUsageRecords: (records) => set({ usageRecords: records }),

  costSummary: null,
  setCostSummary: (summary) => set({ costSummary: summary }),

  modelPrices: null,
  setModelPrices: (prices) => set({ modelPrices: prices }),

  isWindowVisible: false,
  setWindowVisible: (visible) => set({ isWindowVisible: visible }),
  toggleWindow: () => set((s) => ({ isWindowVisible: !s.isWindowVisible })),
}))
