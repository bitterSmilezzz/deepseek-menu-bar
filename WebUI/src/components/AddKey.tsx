import { useState } from 'react'
import type { NativeMethod } from '../hooks/useBridge'

interface AddKeyProps {
  onBack: () => void
  callNative: <T = any>(method: NativeMethod, params?: any) => Promise<T>
}

export default function AddKey({ onBack, callNative }: AddKeyProps) {
  const [name, setName] = useState('')
  const [key, setKey] = useState('sk-')
  const [saving, setSaving] = useState(false)
  const [done, setDone] = useState(false)

  async function handleSave() {
    if (!name.trim() || !key.trim()) return
    setSaving(true)
    try {
      await callNative('saveApiKey', { name: name.trim(), key: key.trim() })
      setDone(true)
      setTimeout(() => onBack(), 1500)
    } catch {
      // ignore
    } finally {
      setSaving(false)
    }
  }

  if (done) {
    return (
      <div className="flex flex-col items-center justify-center py-12 animate-[fadeIn_0.3s_ease-out]">
        <span className="text-3xl mb-3">✅</span>
        <div className="text-sm font-medium" style={{ color: 'var(--text-primary)' }}>API Key 已保存</div>
        <div className="text-xs mt-1" style={{ color: 'var(--text-tertiary)' }}>即将返回首页</div>
      </div>
    )
  }

  return (
    <div className="space-y-4">
      <button onClick={onBack} className="flex items-center gap-1.5 text-xs transition-all duration-200 hover:opacity-70" style={{ color: 'var(--btn-text)' }}>
        ← 返回
      </button>

      <div className="rounded-xl p-3 border" style={{ background: 'rgba(239,68,68,0.06)', borderColor: 'rgba(239,68,68,0.12)' }}>
        <div className="flex items-start gap-2">
          <span className="text-sm mt-0.5">⚠️</span>
          <div>
            <div className="text-xs font-medium" style={{ color: '#ef4444' }}>安全提醒</div>
            <div className="text-[11px] mt-0.5" style={{ color: 'rgba(239,68,68,0.7)' }}>
              DeepSeek 官网的 API Key 仅创建时显示一次，请妥善保管。
            </div>
          </div>
        </div>
      </div>

      <div className="space-y-3">
        <div>
          <div className="text-xs font-medium mb-1.5" style={{ color: 'var(--text-tertiary)' }}>名称</div>
          <input
            value={name}
            onChange={e => setName(e.target.value)}
            placeholder="例如：主账号、开发环境"
            className="w-full rounded-xl px-3 py-2.5 text-sm outline-none transition-all duration-200 border"
            style={{ background: 'var(--card-bg)', borderColor: 'var(--card-border)', color: 'var(--text-primary)' }}
            onFocus={(e) => { e.currentTarget.style.borderColor = 'rgba(59,130,246,0.3)' }}
            onBlur={(e) => { e.currentTarget.style.borderColor = 'var(--card-border)' }}
          />
        </div>

        <div>
          <div className="text-xs font-medium mb-1.5" style={{ color: 'var(--text-tertiary)' }}>API Key</div>
          <input
            value={key}
            onChange={e => setKey(e.target.value)}
            placeholder="sk-..."
            className="w-full rounded-xl px-3 py-2.5 text-sm outline-none transition-all duration-200 border font-mono"
            style={{ background: 'var(--card-bg)', borderColor: 'var(--card-border)', color: 'var(--text-primary)' }}
            onFocus={(e) => { e.currentTarget.style.borderColor = 'rgba(59,130,246,0.3)' }}
            onBlur={(e) => { e.currentTarget.style.borderColor = 'var(--card-border)' }}
          />
        </div>
      </div>

      <button
        onClick={handleSave}
        disabled={!name.trim() || !key.trim() || saving}
        className="w-full rounded-xl py-2.5 text-sm font-medium transition-all duration-200 disabled:opacity-40"
        style={{
          background: 'linear-gradient(135deg, #3B82F6, #8B5CF6)',
          color: '#fff',
        }}
      >
        {saving ? '保存中...' : '保存'}
      </button>

      <div className="flex items-center gap-2 pt-1">
        <span className="text-sm">🔒</span>
        <span className="text-[11px]" style={{ color: 'var(--text-muted)' }}>
          Key 仅安全存储在本地钥匙串中
        </span>
      </div>
    </div>
  )
}
