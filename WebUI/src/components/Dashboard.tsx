import { useEffect } from 'react'
import { useAppStore } from '../stores/appStore'
import { useBridge } from '../hooks/useBridge'
import type { Page, DailyStats } from '../types'

interface DashboardProps {
  onNavigate: (page: Page) => void
}

export default function Dashboard({ onNavigate }: DashboardProps) {
  const { proxyStatus, todayStats, costSummary, isPinned, setPinned,
          setProxyStatus, setTodayStats, setCostSummary } = useAppStore()
  const { callNative } = useBridge()

  useEffect(() => {
    loadData()
    const interval = setInterval(loadData, 10000)
    return () => clearInterval(interval)
  }, [])

  async function loadData() {
    try {
      const status = await callNative<any>('getProxyStatus').catch(() => null)
      if (status) setProxyStatus(status)

      const stats = await callNative<DailyStats>('getTodayStats').catch(() => null)
      if (stats) setTodayStats(stats)

      const summary = await callNative<any>('getCostSummary').catch(() => null)
      if (summary) setCostSummary(summary)
    } catch {}
  }

  function fmtNum(n: number): string {
    if (n >= 1000000) return (n / 1_000_000).toFixed(1) + 'M'
    if (n >= 1000) return (n / 1000).toFixed(1) + 'K'
    return String(n)
  }

  const mainMenuItems = [
    { id: 'proxy', icon: '🌐', label: '代理控制', desc: '启动/停止 HTTP 拦截代理' },
    { id: 'stats', icon: '📊', label: '用量统计', desc: 'Token 消耗图表分析' },
    { id: 'pricing', icon: '💰', label: '模型定价', desc: '各厂商模型价格对比' },
    { id: 'history', icon: '📋', label: '历史记录', desc: '查看所有 API 调用记录' },
  ]

  const bottomItems = [
    { id: 'settings', icon: '⚙️', label: '设置', desc: 'API Key 与主题管理' },
  ]

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-2">
          <span className="text-lg">🐋</span>
          <div>
            <div className="font-semibold text-sm" style={{ color: 'var(--text-primary)' }}>DeepSeek 工具箱</div>
            <div className="text-[10px]" style={{ color: proxyStatus.running ? '#10B981' : 'var(--text-muted)' }}>
              {proxyStatus.running ? `🟢 代理运行中 :${proxyStatus.port}` : '⚪ 代理未启动'}
            </div>
          </div>
        </div>
      </div>

      <div className="rounded-2xl p-4 border" style={{
        background: proxyStatus.running ? 'rgba(16,185,129,0.06)' : 'rgba(239,68,68,0.04)',
        borderColor: proxyStatus.running ? 'rgba(16,185,129,0.15)' : 'rgba(239,68,68,0.1)'
      }}>
        <div className="flex items-center justify-between">
          <div className="text-xs font-medium" style={{ color: 'var(--text-secondary)' }}>
            {proxyStatus.running ? '正在监听 AI API 流量' : '点击下方启动代理'}
          </div>
          <button onClick={() => onNavigate('proxy')} className="text-[10px] px-2.5 py-1 rounded-lg font-medium transition"
            style={{
              background: proxyStatus.running ? 'rgba(16,185,129,0.15)' : 'linear-gradient(135deg,#3B82F6,#8B5CF6)',
              color: proxyStatus.running ? '#10B981' : '#fff'
            }}>
            {proxyStatus.running ? '管理' : '启动代理'}
          </button>
        </div>
        {proxyStatus.running && (
          <div className="mt-2 text-[11px] font-mono" style={{ color: 'var(--text-muted)' }}>
            HTTP 代理: 127.0.0.1:{proxyStatus.port} &nbsp;
            <button onClick={() => { navigator.clipboard.writeText(`127.0.0.1:${proxyStatus.port}`) }}
              className="text-xs" style={{ color: 'var(--btn-text)' }}>📋</button>
          </div>
        )}
      </div>

      {todayStats && todayStats.totalRequests > 0 ? (
        <div className="space-y-3">
          <div className="grid grid-cols-3 gap-2">
            {[
              { label: '请求数', value: String(todayStats.totalRequests) },
              { label: '输入', value: fmtNum(todayStats.totalInputTokens) },
              { label: '输出', value: fmtNum(todayStats.totalOutputTokens) },
              { label: '缓存命中', value: fmtNum(todayStats.totalCacheHitTokens), color: '#10B981' },
              { label: `费用 ¥`, value: todayStats.totalCostRMB.toFixed(2), highlight: true },
              { label: `费用 $`, value: todayStats.totalCostUSD.toFixed(4), highlight: true },
            ].map((item, i) => (
              <div key={i} className="rounded-xl p-3 text-center border"
                style={{
                  background: item.highlight ? 'rgba(59,130,246,0.06)' : 'var(--card-bg)',
                  borderColor: item.highlight ? 'rgba(59,130,246,0.15)' : 'var(--card-border)'
                }}>
                <div className="text-[10px] font-medium mb-1" style={{ color: 'var(--text-tertiary)' }}>{item.label}</div>
                <div className="text-sm font-bold" style={{ color: item.color || 'var(--text-primary)' }}>{item.value}</div>
              </div>
            ))}
          </div>

          <div className="space-y-1">
            <div className="text-[10px] font-medium" style={{ color: 'var(--text-tertiary)' }}>模型用量排行</div>
            {Object.entries(todayStats.modelBreakdown)
              .sort((a, b) => (b[1].inputTokens + b[1].outputTokens) - (a[1].inputTokens + a[1].outputTokens))
              .slice(0, 5)
              .map(([key, stat], i) => (
                <div key={key} className="flex items-center gap-2 rounded-lg px-3 py-2 border text-xs"
                  style={{ background: 'var(--card-bg)', borderColor: 'var(--card-border)' }}>
                  <span className="font-mono text-[10px] w-5" style={{ color: 'var(--text-muted)' }}>#{i + 1}</span>
                  <span className="flex-1 font-mono truncate" style={{ color: 'var(--text-primary)' }}>{key}</span>
                  <span style={{ color: 'var(--text-tertiary)' }}>{fmtNum(stat.inputTokens + stat.outputTokens)}</span>
                  <span style={{ color: 'var(--text-primary)' }}>¥{stat.costRMB.toFixed(2)}</span>
                </div>
              ))}
          </div>
        </div>
      ) : (
        <div className="text-center py-6">
          <div className="text-2xl mb-2">📡</div>
          <div className="text-xs" style={{ color: 'var(--text-muted)' }}>
            {proxyStatus.running ? '等待 AI 请求...' : '启动代理后开始监控'}
          </div>
        </div>
      )}

      <div className="space-y-1">
        {mainMenuItems.map((item) => (
          <button key={item.id} onClick={() => onNavigate(item.id as Page)}
            className="w-full flex items-center gap-3 rounded-xl p-3 transition-all duration-200 border"
            style={{ background: 'var(--card-bg)', borderColor: 'var(--card-border)' }}
            onMouseEnter={e => { e.currentTarget.style.background = 'var(--card-hover)' }}
            onMouseLeave={e => { e.currentTarget.style.background = 'var(--card-bg)' }}>
            <span className="text-lg">{item.icon}</span>
            <div className="flex-1 text-left">
              <div className="text-sm font-medium" style={{ color: 'var(--text-primary)' }}>{item.label}</div>
              <div className="text-[11px]" style={{ color: 'var(--text-tertiary)' }}>{item.desc}</div>
            </div>
            <span className="text-sm" style={{ color: 'var(--btn-text)' }}>›</span>
          </button>
        ))}
      </div>

      <div className="flex items-center justify-between pt-1">
        <button onClick={() => setPinned(!isPinned)}
          className="flex items-center gap-1.5 text-xs px-2.5 py-1.5 rounded-lg transition"
          style={{ color: 'var(--btn-text)', background: 'var(--card-bg)' }}>
          <span className={isPinned ? 'rotate-45' : ''}>📌</span>
          {isPinned ? '已固定' : '置顶'}
        </button>
        <div className="flex items-center gap-1">
          {bottomItems.map(item => (
            <button key={item.id} onClick={() => onNavigate(item.id as Page)}
              className="text-xs px-2.5 py-1.5 rounded-lg transition"
              style={{ color: 'var(--btn-text)', background: 'var(--card-bg)' }}>
              {item.icon} {item.label}
            </button>
          ))}
        </div>
      </div>
    </div>
  )
}
