import { useState, useEffect } from 'react'
import { useAppStore } from '../stores/appStore'
import { useBridge } from '../hooks/useBridge'
import type { ProxyStatus } from '../types'

interface Props { onBack: () => void }

export default function ProxyControl({ onBack }: Props) {
  const { proxyStatus, setProxyStatus } = useAppStore()
  const { callNative } = useBridge()
  const [loading, setLoading] = useState(false)
  const [copied, setCopied] = useState(false)

  useEffect(() => {
    refreshStatus()
  }, [])

  async function refreshStatus() {
    try {
      const status = await callNative<ProxyStatus>('getProxyStatus')
      if (status) setProxyStatus(status)
    } catch {}
  }

  async function startProxy() {
    setLoading(true)
    try {
      const result = await callNative<{ port: number }>('startProxy')
      if (result) setProxyStatus({ running: true, port: result.port, caInstalled: proxyStatus.caInstalled })
    } catch {}
    setLoading(false)
  }

  async function stopProxy() {
    setLoading(true)
    try {
      await callNative('stopProxy')
      setProxyStatus({ ...proxyStatus, running: false })
    } catch {}
    setLoading(false)
  }

  function copyAddress() {
    navigator.clipboard.writeText(`127.0.0.1:${proxyStatus.port}`)
    setCopied(true)
    setTimeout(() => setCopied(false), 1500)
  }

  return (
    <div className="space-y-4">
      <button onClick={onBack} className="flex items-center gap-1.5 text-xs" style={{ color: 'var(--btn-text)' }}>← 返回</button>

      <div className="text-sm font-semibold" style={{ color: 'var(--text-primary)' }}>代理控制</div>

      <div className="rounded-xl p-4 border text-center" style={{
        background: proxyStatus.running ? 'rgba(16,185,129,0.08)' : 'rgba(239,68,68,0.06)',
        borderColor: proxyStatus.running ? 'rgba(16,185,129,0.15)' : 'rgba(239,68,68,0.12)'
      }}>
        <div className="text-2xl mb-1">{proxyStatus.running ? '🟢' : '🔴'}</div>
        <div className="text-sm font-medium" style={{ color: proxyStatus.running ? '#10B981' : '#ef4444' }}>
          {proxyStatus.running ? '代理运行中' : '代理已停止'}
        </div>
      </div>

      <div className="space-y-2">
        <div className="flex items-center justify-between rounded-xl px-3 py-2.5 border" style={{ background: 'var(--card-bg)', borderColor: 'var(--card-border)' }}>
          <span className="text-xs" style={{ color: 'var(--text-tertiary)' }}>端口</span>
          <span className="text-sm font-mono font-medium" style={{ color: 'var(--text-primary)' }}>{proxyStatus.port}</span>
        </div>

        <div className="flex items-center justify-between rounded-xl px-3 py-2.5 border" style={{ background: 'var(--card-bg)', borderColor: 'var(--card-border)' }}>
          <span className="text-xs" style={{ color: 'var(--text-tertiary)' }}>HTTP 代理地址</span>
          <button onClick={copyAddress} className="text-xs font-mono px-2 py-0.5 rounded" style={{ background: 'var(--card-hover)', color: 'var(--text-primary)' }}>
            127.0.0.1:{proxyStatus.port} {copied ? '✅' : '📋'}
          </button>
        </div>
      </div>

      <button
        onClick={proxyStatus.running ? stopProxy : startProxy}
        disabled={loading}
        className="w-full rounded-xl py-2.5 text-sm font-medium transition-all duration-200"
        style={{
          background: proxyStatus.running ? '#ef4444' : 'linear-gradient(135deg,#3B82F6,#8B5CF6)',
          color: '#fff',
          opacity: loading ? 0.6 : 1,
        }}
      >
        {loading ? '处理中...' : proxyStatus.running ? '停止代理' : '启动代理'}
      </button>

      <div className="space-y-2 border-t pt-3" style={{ borderColor: 'var(--divider)' }}>
        <div className="text-xs font-medium" style={{ color: 'var(--text-secondary)' }}>📜 证书安装</div>
        <p className="text-[11px]" style={{ color: 'var(--text-muted)' }}>
          需安装 CA 证书才能解密 HTTPS 流量。启动代理后，在 Finder 中找到证书文件双击安装到钥匙串。
        </p>
        <div className="flex gap-2">
          <button
            onClick={async () => { try { await callNative('installCACert') } catch {} }}
            className="flex-1 rounded-lg py-1.5 text-xs border transition"
            style={{ background: 'var(--card-bg)', borderColor: 'var(--card-border)', color: 'var(--btn-text)' }}
          >📥 导出证书</button>
        </div>
      </div>

      <div className="space-y-1 border-t pt-3" style={{ borderColor: 'var(--divider)' }}>
        <div className="text-xs font-medium mb-2" style={{ color: 'var(--text-secondary)' }}>📝 配置方法</div>
        <p className="text-[11px] leading-relaxed" style={{ color: 'var(--text-muted)' }}>
          • <b>Cursor</b>: Settings → HTTP Proxy → 填入 127.0.0.1:{proxyStatus.port}<br/>
          • <b>ChatGPT</b>: 系统网络代理 → HTTP/HTTPS → 127.0.0.1:{proxyStatus.port}<br/>
          • <b>Claude Code</b>: 设置环境变量 HTTP_PROXY=http://127.0.0.1:{proxyStatus.port}
        </p>
      </div>
    </div>
  )
}
