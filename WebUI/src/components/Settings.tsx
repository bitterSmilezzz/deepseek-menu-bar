import { useState } from 'react'
import { useAppStore } from '../stores/appStore'
import type { NativeMethod } from '../hooks/useBridge'
import type { Page } from '../types'

interface SettingsProps {
  onNavigate: (page: Page) => void
  callNative: <T = any>(method: NativeMethod, params?: any) => Promise<T>
}

export default function Settings({ onNavigate, callNative }: SettingsProps) {
  const { apiKeys, theme, toggleTheme, setActiveKeyId } = useAppStore()
  const [visibleKeys, setVisibleKeys] = useState<Record<string, boolean>>({})

  async function handleDelete(id: string) {
    try {
      await callNative('deleteApiKey', { id })
      window.location.reload()
    } catch {
      // ignore
    }
  }

  async function handleSetActive(id: string) {
    try {
      await callNative('setActiveKey', { id })
      setActiveKeyId(id)
      window.location.reload()
    } catch {
      // ignore
    }
  }

  function toggleVisible(id: string) {
    setVisibleKeys(prev => ({ ...prev, [id]: !prev[id] }))
  }

  async function copyKey(key: string) {
    try {
      await navigator.clipboard.writeText(key)
      const btn = document.activeElement as HTMLElement
      if (btn) {
        btn.textContent = '✅'
        setTimeout(() => { btn.textContent = '📋' }, 1500)
      }
    } catch {
      // ignore
    }
  }

  return (
    <div className="space-y-4">
      <button onClick={() => onNavigate('dashboard')} className="flex items-center gap-1.5 text-xs transition-all duration-200 hover:opacity-70" style={{ color: 'var(--btn-text)' }}>
        ← 返回
      </button>

      <div className="space-y-3">
        <div className="text-sm font-semibold" style={{ color: 'var(--text-primary)' }}>API Key 管理</div>

        {apiKeys.map((apiKey) => (
          <div key={apiKey.id} className="rounded-xl p-3 border transition-all duration-200" style={{ background: 'var(--card-bg)', borderColor: apiKey.isActive ? 'rgba(59,130,246,0.2)' : 'var(--card-border)' }}>
            <div className="flex items-center justify-between mb-2">
              <div className="flex items-center gap-2">
                <div className="w-1.5 h-1.5 rounded-full" style={{ background: apiKey.isActive ? '#3B82F6' : 'var(--text-muted)' }} />
                <span className="text-sm font-medium" style={{ color: 'var(--text-primary)' }}>{apiKey.name}</span>
              </div>
              {apiKey.isActive && (
                <span className="text-[9px] px-1.5 py-0.5 rounded font-medium" style={{ background: 'rgba(59,130,246,0.1)', color: '#3B82F6' }}>
                  使用中
                </span>
              )}
            </div>

            <div className="flex items-center justify-between">
              <div className="flex items-center gap-1.5">
                <span className="text-xs font-mono" style={{ color: 'var(--text-tertiary)' }}>
                  {visibleKeys[apiKey.id] ? apiKey.key : apiKey.masked}
                </span>
                <button onClick={() => toggleVisible(apiKey.id)} className="text-xs transition-all duration-200 hover:opacity-70" style={{ color: 'var(--btn-text)' }}>
                  {visibleKeys[apiKey.id] ? '🙈' : '👁️'}
                </button>
                <button onClick={() => copyKey(apiKey.key)} className="text-xs transition-all duration-200 hover:opacity-70" title="复制" style={{ color: 'var(--btn-text)' }}>
                  📋
                </button>
              </div>
              <div className="flex items-center gap-2">
                {!apiKey.isActive && (
                  <button
                    onClick={() => handleSetActive(apiKey.id)}
                    className="text-[10px] px-2 py-0.5 rounded-lg transition-all duration-200"
                    style={{ background: 'var(--card-hover)', color: 'var(--text-tertiary)' }}
                    onMouseEnter={(e) => { e.currentTarget.style.color = '#3B82F6' }}
                    onMouseLeave={(e) => { e.currentTarget.style.color = 'var(--text-tertiary)' }}
                  >
                    启用
                  </button>
                )}
                <button
                  onClick={() => handleDelete(apiKey.id)}
                  className="text-xs transition-all duration-200 hover:opacity-70"
                  style={{ color: 'var(--btn-text)' }}
                >
                  🗑️
                </button>
              </div>
            </div>
          </div>
        ))}

        {apiKeys.length === 0 && (
          <div className="text-center py-6 text-sm" style={{ color: 'var(--text-muted)' }}>
            暂无 API Key
          </div>
        )}

        <button
          onClick={() => onNavigate('addkey')}
          className="w-full rounded-xl py-2.5 text-sm font-medium transition-all duration-200 border"
          style={{ background: 'var(--card-bg)', borderColor: 'var(--card-border)', color: 'var(--text-tertiary)' }}
          onMouseEnter={(e) => { e.currentTarget.style.background = 'var(--card-hover)' }}
          onMouseLeave={(e) => { e.currentTarget.style.background = 'var(--card-bg)' }}
        >
          ＋ 添加 API Key
        </button>
      </div>

      <div className="border-t pt-3" style={{ borderColor: 'var(--divider)' }}>
        <div className="text-sm font-semibold mb-2" style={{ color: 'var(--text-primary)' }}>外观</div>
        <button
          onClick={toggleTheme}
          className="w-full flex items-center justify-between rounded-xl px-3 py-2.5 border transition-all duration-200"
          style={{ background: 'var(--card-bg)', borderColor: 'var(--card-border)' }}
          onMouseEnter={(e) => { e.currentTarget.style.background = 'var(--card-hover)' }}
          onMouseLeave={(e) => { e.currentTarget.style.background = 'var(--card-bg)' }}
        >
          <span className="text-sm" style={{ color: 'var(--text-primary)' }}>{theme === 'dark' ? '🌙 深色模式' : '☀️ 浅色模式'}</span>
          <div className="w-9 h-5 rounded-full relative transition-all duration-300" style={{ background: theme === 'dark' ? 'linear-gradient(135deg, #3B82F6, #8B5CF6)' : 'var(--divider)' }}>
            <div className={`absolute top-0.5 w-4 h-4 rounded-full bg-white shadow transition-all duration-300 ${theme === 'dark' ? 'left-[18px]' : 'left-0.5'}`} />
          </div>
        </button>
      </div>

      <div className="border-t pt-3" style={{ borderColor: 'var(--divider)' }}>
        <div className="flex items-center justify-center gap-4">
          <button onClick={() => onNavigate('tools')} className="text-xs transition-all duration-200" style={{ color: 'var(--btn-text)' }}>工具列表</button>
          <span className="text-xs" style={{ color: 'var(--text-muted)' }}>·</span>
          <button onClick={() => onNavigate('news')} className="text-xs transition-all duration-200" style={{ color: 'var(--btn-text)' }}>最新资讯</button>
          <span className="text-xs" style={{ color: 'var(--text-muted)' }}>·</span>
          <button onClick={() => window.location.reload()} className="text-xs transition-all duration-200" style={{ color: 'var(--btn-text)' }}>刷新</button>
        </div>
      </div>
    </div>
  )
}
