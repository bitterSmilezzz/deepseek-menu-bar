import { useAppStore } from '../stores/appStore'
import type { Page } from '../types'

interface DashboardProps {
  onNavigate: (page: Page) => void
}

export default function Dashboard({ onNavigate }: DashboardProps) {
  const { balance, usage, apiKeys, isPinned, setPinned } = useAppStore()
  const activeKey = apiKeys.find(k => k.isActive)

  const menuItems = [
    { id: 'addkey' as Page, icon: '🔑', label: 'API Key 管理', desc: '添加或切换 API Key' },
    { id: 'tools' as Page, icon: '🧰', label: '工具列表', desc: '查看可用工具' },
    { id: 'news' as Page, icon: '📰', label: '最新资讯', desc: 'DeepSeek 最新动态' },
  ]

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-2">
          <span className="text-lg">🤖</span>
          <span className="font-semibold text-sm" style={{ color: 'var(--text-primary)' }}>
            {activeKey?.name || 'DeepSeek'}
          </span>
        </div>
        <div className="flex items-center gap-1.5">
          {apiKeys.length > 0 && (
            <button
              onClick={() => onNavigate('addkey')}
              className="px-2.5 py-1 rounded-lg text-xs font-medium transition-all duration-200 hover:scale-105"
              style={{ background: 'linear-gradient(135deg, #3B82F6, #8B5CF6)', color: '#fff' }}
            >
              切换
            </button>
          )}
        </div>
      </div>

      <div
        className="rounded-2xl p-4 border"
        style={{ background: 'var(--balance-bg)', borderColor: 'var(--balance-border)' }}
      >
        <div className="text-xs font-medium mb-1" style={{ color: 'var(--text-tertiary)' }}>账户余额</div>
        <div className="flex items-baseline gap-1">
          <span className="text-3xl font-bold" style={{ background: 'linear-gradient(135deg, #3B82F6, #8B5CF6)', WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent' }}>
            ${balance?.balance.toFixed(2) || '0.00'}
          </span>
          <span className="text-xs" style={{ color: 'var(--text-tertiary)' }}>{balance?.currency || 'USD'}</span>
        </div>
      </div>

      {usage && (
        <div className="grid grid-cols-3 gap-2">
          {[
            { label: '输入', value: usage.inputTokens.toLocaleString() },
            { label: '输出', value: usage.outputTokens.toLocaleString() },
            { label: '总计', value: usage.totalTokens.toLocaleString() },
          ].map((item) => (
            <div
              key={item.label}
              className="rounded-xl p-3 text-center border transition-all duration-200"
              style={{ background: 'var(--card-bg)', borderColor: 'var(--card-border)' }}
            >
              <div className="text-[10px] font-medium mb-1" style={{ color: 'var(--text-tertiary)' }}>{item.label}</div>
              <div className="text-sm font-semibold" style={{ color: 'var(--text-primary)' }}>{item.value}</div>
            </div>
          ))}
        </div>
      )}

      <div className="space-y-1">
        {menuItems.map((item) => (
          <button
            key={item.id}
            onClick={() => onNavigate(item.id)}
            className="w-full flex items-center gap-3 rounded-xl p-3 transition-all duration-200 group border"
            style={{ background: 'var(--card-bg)', borderColor: 'var(--card-border)' }}
            onMouseEnter={(e) => { e.currentTarget.style.background = 'var(--card-hover)' }}
            onMouseLeave={(e) => { e.currentTarget.style.background = 'var(--card-bg)' }}
          >
            <span className="text-lg">{item.icon}</span>
            <div className="flex-1 text-left">
              <div className="text-sm font-medium" style={{ color: 'var(--text-primary)' }}>{item.label}</div>
              <div className="text-[11px]" style={{ color: 'var(--text-tertiary)' }}>{item.desc}</div>
            </div>
            <span className="text-sm transition-transform duration-200 group-hover:translate-x-0.5" style={{ color: 'var(--btn-text)' }}>›</span>
          </button>
        ))}
      </div>

      <div className="flex items-center justify-between pt-1">
        <button
          onClick={() => {
            setPinned(!isPinned)
            // callNative?.('togglePin')
          }}
          className="flex items-center gap-1.5 text-xs px-2.5 py-1.5 rounded-lg transition-all duration-200"
          style={{ color: 'var(--btn-text)', background: 'var(--card-bg)' }}
          onMouseEnter={(e) => { e.currentTarget.style.background = 'var(--btn-hover-bg)' }}
          onMouseLeave={(e) => { e.currentTarget.style.background = 'var(--card-bg)' }}
        >
          <span className={`transition-transform duration-200 ${isPinned ? 'rotate-45' : ''}`}>📌</span>
          {isPinned ? '已固定' : '置顶'}
        </button>

        <div className="flex items-center gap-1">
          <button
            onClick={() => window.location.reload()}
            className="text-xs px-2.5 py-1.5 rounded-lg transition-all duration-200"
            style={{ color: 'var(--btn-text)', background: 'var(--card-bg)' }}
            onMouseEnter={(e) => { e.currentTarget.style.background = 'var(--btn-hover-bg)' }}
            onMouseLeave={(e) => { e.currentTarget.style.background = 'var(--card-bg)' }}
          >
            🔄 刷新
          </button>
          <button
            onClick={() => onNavigate('settings')}
            className="text-xs px-2.5 py-1.5 rounded-lg transition-all duration-200"
            style={{ color: 'var(--btn-text)', background: 'var(--card-bg)' }}
            onMouseEnter={(e) => { e.currentTarget.style.background = 'var(--btn-hover-bg)' }}
            onMouseLeave={(e) => { e.currentTarget.style.background = 'var(--card-bg)' }}
          >
            ⚙️ 设置
          </button>
        </div>
      </div>
    </div>
  )
}
