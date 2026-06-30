export type NativeMethod = 'getBalance' | 'getUsage' | 'getTools' | 'searchNews' |
  'getApiKeys' | 'saveApiKey' | 'deleteApiKey' | 'setActiveKey' |
  'togglePin' | 'quitApp' | 'toggleWindow' |
  'startProxy' | 'stopProxy' | 'getProxyStatus' |
  'installCACert' |
  'getUsageRecords' | 'getTodayStats' | 'getRecentStats' |
  'getCostSummary' | 'getAllPrices' | 'getHistory'

const BRIDGE_TIMEOUT = 10000

export function useBridge() {
  const isNative = typeof window !== 'undefined' &&
    !!(window as any).webkit?.messageHandlers?.bridge

  function callNative<T = any>(method: NativeMethod, params?: any): Promise<T> {
    if (!isNative) {
      return handleMock(method, params) as Promise<T>
    }

    return new Promise((resolve, reject) => {
      const requestId = 'req_' + Date.now() + '_' + Math.random().toString(36).substr(2, 9)
      const timeout = setTimeout(() => {
        window.removeEventListener('nativeBridgeResponse', handler)
        reject(new Error(`Bridge timeout: ${method}`))
      }, BRIDGE_TIMEOUT)

      function handler(event: Event) {
        const detail = (event as CustomEvent).detail
        if (detail.request_id === requestId) {
          window.removeEventListener('nativeBridgeResponse', handler)
          clearTimeout(timeout)
          if (detail.type === 'error') {
            reject(new Error(detail.error || 'Unknown error'))
          } else {
            resolve(detail.data as T)
          }
        }
      }

      window.addEventListener('nativeBridgeResponse', handler)

      try {
        ;(window as any).webkit.messageHandlers.bridge.postMessage({
          method: method,
          params: params ?? {},
          request_id: requestId,
        })
      } catch (e: any) {
        window.removeEventListener('nativeBridgeResponse', handler)
        clearTimeout(timeout)
        handleMock(method, params).then(resolve as any).catch(reject)
      }
    })
  }

  return { callNative, isNative }
}

export function quitNativeApp() {
  try {
    ;(window as any).webkit?.messageHandlers?.bridge?.postMessage({
      method: 'quitApp',
      params: {},
      request_id: 'quit_' + Date.now(),
    })
  } catch {}
}

async function handleMock(method: NativeMethod, params?: any) {
  await new Promise(r => setTimeout(r, 200))

  const today = new Date().toISOString().split('T')[0]

  switch (method) {
    case 'getBalance':
      return { balance: 12.34, currency: 'USD', status: 'active' as const }
    case 'getUsage':
      return { inputTokens: 45231, outputTokens: 12089, totalTokens: 57320, date: today }
    case 'getTools':
      return [
        { id: '1', name: 'HTTP 代理', description: '拦截并分析 AI API 流量', icon: '🌐', category: 'proxy' },
        { id: '2', name: '用量统计', description: 'Token 消耗与费用追踪', icon: '📊', category: 'analytics' },
        { id: '3', name: '模型定价', description: '50+ 模型实时定价对比', icon: '💰', category: 'pricing' },
        { id: '4', name: '安全存储', description: 'Keychain 加密存储 API Key', icon: '🔒', category: 'safety' },
        { id: '5', name: '证书管理', description: 'HTTPS 解密 CA 证书', icon: '📜', category: 'safety' },
      ]
    case 'searchNews':
      return [
        { id: '1', title: 'OpenAI 发布 GPT-5 预览版', source: 'TechCrunch', time: '2 小时前', url: '#', isNew: true },
        { id: '2', title: 'Anthropic 推出 Claude 4 系列', source: '官方公告', time: '1 天前', url: '#' },
        { id: '3', title: 'DeepSeek 开源新模型架构', source: 'GitHub', time: '3 天前', url: '#' },
      ]
    case 'getApiKeys':
      return [
        { id: '1', name: 'DeepSeek 主账号', key: 'sk-8a3f...2b1e', masked: 'sk-8a3f••••••2b1e', createdAt: '2026-06-01', isActive: true },
      ]
    case 'saveApiKey':
      return { id: params?.id || 'new', name: params?.name || 'Key', key: params?.key || '', createdAt: today }
    case 'deleteApiKey':
    case 'setActiveKey':
      return { success: true }
    case 'togglePin':
      return { pinned: true }
    case 'quitApp':
    case 'toggleWindow':
      return true
    case 'startProxy':
      return { port: 10080 }
    case 'stopProxy':
      return { success: true }
    case 'getProxyStatus':
      return { running: false, port: 10080, caInstalled: false }
    case 'getTodayStats':
      return {
        date: today, totalRequests: 12, totalInputTokens: 24560,
        totalOutputTokens: 8900, totalCacheHitTokens: 3200,
        totalCostUSD: 0.12, totalCostRMB: 0.87,
        modelBreakdown: {
          'openai/gpt-4o': { requests: 5, inputTokens: 12000, outputTokens: 4000, cacheHitTokens: 1200, costUSD: 0.06, costRMB: 0.44 },
          'anthropic/claude-sonnet': { requests: 4, inputTokens: 8000, outputTokens: 3000, cacheHitTokens: 1500, costUSD: 0.04, costRMB: 0.29 },
          'deepseek/deepseek-chat': { requests: 3, inputTokens: 4560, outputTokens: 1900, cacheHitTokens: 500, costUSD: 0.02, costRMB: 0.14 },
        }
      }
    case 'getRecentStats':
      return [
        { date: today, totalRequests: 12, totalInputTokens: 24560, totalOutputTokens: 8900, totalCacheHitTokens: 3200, totalCostUSD: 0.12, totalCostRMB: 0.87, modelBreakdown: {} },
        { date: today.replace(/..$/, String(Number(today.slice(-2)) - 1).padStart(2, '0')), totalRequests: 8, totalInputTokens: 18000, totalOutputTokens: 6200, totalCacheHitTokens: 1800, totalCostUSD: 0.08, totalCostRMB: 0.58, modelBreakdown: {} },
        { date: today.replace(/..$/, String(Number(today.slice(-2)) - 2).padStart(2, '0')), totalRequests: 15, totalInputTokens: 32000, totalOutputTokens: 11000, totalCacheHitTokens: 4000, totalCostUSD: 0.18, totalCostRMB: 1.30, modelBreakdown: {} },
        { date: today.replace(/..$/, String(Number(today.slice(-2)) - 3).padStart(2, '0')), totalRequests: 6, totalInputTokens: 9000, totalOutputTokens: 3500, totalCacheHitTokens: 900, totalCostUSD: 0.05, totalCostRMB: 0.36, modelBreakdown: {} },
        { date: today.replace(/..$/, String(Number(today.slice(-2)) - 4).padStart(2, '0')), totalRequests: 20, totalInputTokens: 45000, totalOutputTokens: 15000, totalCacheHitTokens: 6000, totalCostUSD: 0.25, totalCostRMB: 1.81, modelBreakdown: {} },
        { date: today.replace(/..$/, String(Number(today.slice(-2)) - 5).padStart(2, '0')), totalRequests: 10, totalInputTokens: 20000, totalOutputTokens: 7000, totalCacheHitTokens: 2500, totalCostUSD: 0.10, totalCostRMB: 0.73, modelBreakdown: {} },
        { date: today.replace(/..$/, String(Number(today.slice(-2)) - 6).padStart(2, '0')), totalRequests: 18, totalInputTokens: 38000, totalOutputTokens: 14000, totalCacheHitTokens: 5000, totalCostUSD: 0.22, totalCostRMB: 1.60, modelBreakdown: {} },
      ]
    case 'getCostSummary':
      return { totalCostUSD: 1.00, totalCostRMB: 7.25, totalTokens: 195000, totalRequests: 89 }
    case 'getAllPrices':
      return {
        openai: { 'gpt-4o': { input: 2.5, output: 10, cacheHit: 1.25 }, 'gpt-4o-mini': { input: 0.15, output: 0.6, cacheHit: 0.075 } },
        anthropic: { 'claude-sonnet': { input: 3, output: 15, cacheHit: 0.3 }, 'claude-haiku': { input: 0.8, output: 4, cacheHit: 0.08 } },
        deepseek: { 'deepseek-chat': { input: 0.27, output: 1.1, cacheHit: 0.07 }, 'deepseek-reasoner': { input: 0.55, output: 2.19 } },
        google: { 'gemini-2.0-flash': { input: 0.1, output: 0.4 } },
        moonshot: { 'moonshot-v1-8k': { input: 0.24, output: 0.24 } },
        zhipu: { 'glm-4-plus': { input: 0.5, output: 0.5 } },
        qwen: { 'qwen-max': { input: 2, output: 6 }, 'qwen-plus': { input: 0.8, output: 2 } },
        minimax: { 'abab6.5s': { input: 0.1, output: 0.1 } },
        mistral: { 'mistral-large': { input: 2, output: 6 } },
        groq: { 'llama-3.3-70b': { input: 0.59, output: 0.79 } },
        xai: { 'grok-2': { input: 2, output: 10 } },
      }
    case 'getUsageRecords':
    case 'getHistory':
      return Array.from({ length: 20 }, (_, i) => ({
        id: `rec_${Date.now() - i * 60000}_${i}`,
        timestamp: (Date.now() - i * 60000) / 1000,
        tool: ['Cursor', 'Claude Code', 'ChatGPT', 'API'][i % 4],
        provider: ['openai', 'anthropic', 'deepseek'][i % 3],
        model: ['gpt-4o', 'claude-sonnet', 'deepseek-chat'][i % 3],
        requestTokens: 1200 + i * 100, responseTokens: 500 + i * 50,
        cacheHitTokens: i * 30, cacheMissTokens: 1200 + i * 70,
        costUSD: 0.005 + i * 0.001, costRMB: (0.005 + i * 0.001) * 7.25,
        endpoint: ['https://api.openai.com/v1/chat/completions', 'https://api.anthropic.com/v1/messages'][i % 2],
      }))
    default:
      return null
  }
}
