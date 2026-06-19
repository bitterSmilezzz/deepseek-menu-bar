export type NativeMethod = 'getBalance' | 'getUsage' | 'getTools' | 'searchNews' |
  'getApiKeys' | 'saveApiKey' | 'deleteApiKey' | 'setActiveKey' | 'togglePin' | 'quitApp'

const BRIDGE_TIMEOUT = 10000

export function useBridge() {
  const isNative = false // 当前使用 Mock 数据模式

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
  await new Promise(r => setTimeout(r, 300))

  switch (method) {
    case 'getBalance':
      return { balance: 12.34, currency: 'USD', status: 'active' }
    case 'getUsage':
      return { inputTokens: 45231, outputTokens: 12089, totalTokens: 57320, date: new Date().toISOString().split('T')[0] }
    case 'getTools':
      return [
        { id: '1', name: '联网搜索', description: '实时搜索互联网信息', icon: '🔍', category: 'utility' },
        { id: '2', name: '文件读取', description: '读取并分析上传的文件内容', icon: '📄', category: 'utility' },
        { id: '3', name: '代码执行', description: '沙箱环境执行代码', icon: '💻', category: 'utility' },
        { id: '4', name: '图像理解', description: '识别并分析图像内容', icon: '🖼️', category: 'vision' },
        { id: '5', name: '语音识别', description: '音频转文字处理', icon: '🎤', category: 'audio' },
      ]
    case 'searchNews':
      return [
        { id: '1', title: 'DeepSeek R2 模型即将发布', source: '机器之心', time: '2 小时前', url: '#', isNew: true },
        { id: '2', title: 'DeepSeek API 价格调整公告', source: '官方公告', time: '1 天前', url: '#' },
        { id: '3', title: 'DeepSeek 开源新模型架构', source: 'GitHub', time: '3 天前', url: '#' },
        { id: '4', title: 'DeepSeek 与多家云厂商达成合作', source: '36氪', time: '5 天前', url: '#' },
      ]
    case 'getApiKeys':
      return [
        { id: '1', name: 'DeepSeek 主账号', key: 'sk-8a3f...2b1e', masked: 'sk-8a3f••••••2b1e', createdAt: '2026-06-01', isActive: true },
        { id: '2', name: '备用账号', key: 'sk-c7d2...3f8a', masked: 'sk-c7d2••••••3f8a', createdAt: '2026-06-05', isActive: false },
      ]
    case 'saveApiKey':
      return { id: '3', name: params?.name || 'New Key', key: params?.key || '', createdAt: new Date().toISOString() }
    case 'deleteApiKey':
      return { success: true }
    case 'setActiveKey':
      return { success: true }
    case 'togglePin':
      return { pinned: true }
    case 'quitApp':
      return true
    default:
      return null
  }
}
