import { useState, useEffect } from 'react'
import { useAppStore } from '../stores/appStore'
import type { NativeMethod } from '../hooks/useBridge'

interface NewsFeedProps {
  onBack: () => void
  callNative: <T = any>(method: NativeMethod, params?: any) => Promise<T>
}

export default function NewsFeed({ onBack, callNative }: NewsFeedProps) {
  const { news, setNews, newsQuery, setNewsQuery } = useAppStore()
  const [loading, setLoading] = useState(false)

  useEffect(() => {
    loadNews()
  }, [])

  async function loadNews() {
    setLoading(true)
    try {
      const data = await callNative<any[]>('searchNews')
      if (data) setNews(data)
    } catch {
      // ignore
    } finally {
      setLoading(false)
    }
  }

  const filtered = newsQuery
    ? news.filter(item => item.title.toLowerCase().includes(newsQuery.toLowerCase()))
    : news

  return (
    <div className="space-y-3">
      <button onClick={onBack} className="flex items-center gap-1.5 text-xs transition-all duration-200 hover:opacity-70" style={{ color: 'var(--btn-text)' }}>
        ← 返回
      </button>

      <div className="text-sm font-semibold" style={{ color: 'var(--text-primary)' }}>最新资讯</div>

      <div className="relative">
        <span className="absolute left-3 top-1/2 -translate-y-1/2 text-xs" style={{ color: 'var(--text-muted)' }}>🔍</span>
        <input
          value={newsQuery}
          onChange={e => setNewsQuery(e.target.value)}
          placeholder="搜索资讯..."
          className="w-full rounded-xl pl-8 pr-3 py-2 text-xs outline-none border transition-all duration-200"
          style={{ background: 'var(--card-bg)', borderColor: 'var(--card-border)', color: 'var(--text-primary)' }}
          onFocus={(e) => { e.currentTarget.style.borderColor = 'rgba(59,130,246,0.3)' }}
          onBlur={(e) => { e.currentTarget.style.borderColor = 'var(--card-border)' }}
        />
      </div>

      <div className="space-y-1">
        {filtered.map((item) => (
          <div
            key={item.id}
            className="flex items-start gap-3 rounded-xl p-3 border transition-all duration-200"
            style={{ background: 'var(--card-bg)', borderColor: 'var(--card-border)' }}
          >
            <div className="flex-1 min-w-0">
              <div className="flex items-center gap-2">
                <div className="text-sm font-medium truncate" style={{ color: 'var(--text-primary)' }}>{item.title}</div>
                {item.isNew && (
                  <span className="text-[9px] px-1.5 py-0.5 rounded font-bold shrink-0 animate-[fadeIn_0.5s_ease-out]"
                    style={{ background: 'linear-gradient(135deg, #3B82F6, #8B5CF6)', color: '#fff' }}
                  >
                    NEW
                  </span>
                )}
              </div>
              <div className="flex items-center gap-2 mt-1">
                <span className="text-[11px]" style={{ color: 'var(--text-tertiary)' }}>{item.source}</span>
                <span className="text-[11px]" style={{ color: 'var(--text-muted)' }}>·</span>
                <span className="text-[11px]" style={{ color: 'var(--text-muted)' }}>{item.time}</span>
              </div>
            </div>
          </div>
        ))}
      </div>

      {loading && (
        <div className="text-center py-4 text-xs" style={{ color: 'var(--text-muted)' }}>
          加载中...
        </div>
      )}

      {!loading && filtered.length === 0 && (
        <div className="text-center py-8 text-sm" style={{ color: 'var(--text-muted)' }}>
          {newsQuery ? '未找到匹配资讯' : '暂无资讯'}
        </div>
      )}
    </div>
  )
}
