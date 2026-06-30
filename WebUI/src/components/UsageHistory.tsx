import { useState, useEffect } from 'react'
import { useAppStore } from '../stores/appStore'
import { useBridge } from '../hooks/useBridge'
import type { UsageRecord } from '../types'

interface Props { onBack: () => void }

export default function UsageHistory({ onBack }: Props) {
  const { usageRecords, setUsageRecords } = useAppStore()
  const { callNative } = useBridge()
  const [filter, setFilter] = useState('')

  useEffect(() => {
    const load = async () => {
      const records = await callNative<UsageRecord[]>('getHistory')
      if (records) setUsageRecords(records)
    }
    load()
  }, [])

  const filtered = filter
    ? usageRecords.filter(r =>
        r.model.toLowerCase().includes(filter.toLowerCase()) ||
        r.tool.toLowerCase().includes(filter.toLowerCase()) ||
        r.provider.toLowerCase().includes(filter.toLowerCase()))
    : usageRecords

  function formatTime(ts: number) {
    const d = new Date(ts * 1000)
    return d.toLocaleTimeString('zh-CN', { hour: '2-digit', minute: '2-digit', second: '2-digit' })
  }

  function fmtNum(n: number) {
    if (n >= 1000000) return (n / 1_000_000).toFixed(1) + 'M'
    if (n >= 1000) return (n / 1000).toFixed(1) + 'K'
    return String(n)
  }

  return (
    <div className="space-y-3">
      <button onClick={onBack} className="flex items-center gap-1.5 text-xs" style={{ color: 'var(--btn-text)' }}>← 返回</button>

      <div className="text-sm font-semibold" style={{ color: 'var(--text-primary)' }}>历史记录</div>

      <input
        value={filter}
        onChange={e => setFilter(e.target.value)}
        placeholder="搜索模型/工具..."
        className="w-full rounded-xl px-3 py-2 text-xs outline-none border"
        style={{ background: 'var(--card-bg)', borderColor: 'var(--card-border)', color: 'var(--text-primary)' }}
      />

      <div className="space-y-1 max-h-96 overflow-y-auto">
        {filtered.map(r => (
          <div key={r.id} className="rounded-lg px-3 py-2 border text-xs"
            style={{ background: 'var(--card-bg)', borderColor: 'var(--card-border)' }}>
            <div className="flex items-center justify-between mb-0.5">
              <span className="font-mono" style={{ color: 'var(--text-primary)' }}>{r.model}</span>
              <span style={{ color: 'var(--text-muted)' }}>{formatTime(r.timestamp)}</span>
            </div>
            <div className="flex items-center gap-3" style={{ color: 'var(--text-tertiary)' }}>
              <span>{r.tool}</span>
              <span>⇣{fmtNum(r.requestTokens)}</span>
              <span>⇡{fmtNum(r.responseTokens)}</span>
              <span style={{ color: r.costRMB > 0 ? 'var(--text-primary)' : 'var(--text-muted)' }}>
                ¥{r.costRMB.toFixed(4)}
              </span>
            </div>
          </div>
        ))}
      </div>

      {filtered.length === 0 && (
        <div className="text-center py-8 text-sm" style={{ color: 'var(--text-muted)' }}>
          {filter ? '没有匹配记录' : '暂无历史记录'}
        </div>
      )}
    </div>
  )
}
