import { useState, useEffect } from 'react'
import { useAppStore } from '../stores/appStore'
import { useBridge } from '../hooks/useBridge'
import type { ProviderPrices } from '../types'

interface Props { onBack: () => void }

export default function PricingList({ onBack }: Props) {
  const { modelPrices, setModelPrices } = useAppStore()
  const { callNative } = useBridge()
  const [expandedProvider, setExpandedProvider] = useState<string | null>(null)

  useEffect(() => {
    const load = async () => {
      const prices = await callNative<ProviderPrices>('getAllPrices')
      if (prices) setModelPrices(prices)
    }
    load()
  }, [])

  const providerNames: Record<string, string> = {
    openai: 'OpenAI', anthropic: 'Anthropic', deepseek: 'DeepSeek',
    google: 'Google', moonshot: '月之暗面', zhipu: '智谱AI',
    qwen: '通义千问', minimax: 'MiniMax', baichuan: '百川',
    stepfun: '阶跃星辰', '01ai': '零一万物',
    groq: 'Groq', mistral: 'Mistral', cohere: 'Cohere',
    together: 'Together', fireworks: 'Fireworks',
    perplexity: 'Perplexity', xai: 'xAI',
  }

  if (!modelPrices) {
    return <div className="p-4 text-center text-xs" style={{ color: 'var(--text-muted)' }}>加载中...</div>
  }

  return (
    <div className="space-y-3">
      <button onClick={onBack} className="flex items-center gap-1.5 text-xs" style={{ color: 'var(--btn-text)' }}>← 返回</button>

      <div className="text-sm font-semibold" style={{ color: 'var(--text-primary)' }}>模型定价</div>

      <div className="flex gap-2 text-[10px]" style={{ color: 'var(--text-muted)' }}>
        <span>单位：$ / 1M tokens</span>
        <span>·</span>
        <span>汇率：1 USD ≈ 7.25 CNY</span>
      </div>

      {Object.entries(modelPrices).map(([provider, models]) => (
        <div key={provider}>
          <button
            onClick={() => setExpandedProvider(expandedProvider === provider ? null : provider)}
            className="w-full flex items-center gap-2 rounded-lg px-3 py-2 text-xs font-medium transition"
            style={{ background: 'var(--card-bg)', color: 'var(--text-primary)' }}
          >
            <span>{expandedProvider === provider ? '▼' : '▶'}</span>
            <span>{providerNames[provider] || provider}</span>
            <span style={{ color: 'var(--text-muted)', marginLeft: 'auto', fontSize: 10 }}>
              {Object.keys(models).length} 模型
            </span>
          </button>

          {expandedProvider === provider && (
            <div className="mt-1 space-y-0.5">
              {Object.entries(models).map(([model, price]) => (
                <div key={model} className="rounded-lg px-3 py-2 border text-[11px]"
                  style={{ background: 'var(--card-bg)', borderColor: 'var(--card-border)' }}>
                  <div className="flex items-center justify-between">
                    <span className="font-mono font-medium" style={{ color: 'var(--text-primary)' }}>{model}</span>
                  </div>
                  <div className="flex gap-3 mt-1" style={{ color: 'var(--text-tertiary)' }}>
                    <span>输入: <b style={{ color: 'var(--text-primary)' }}>${price.input}</b></span>
                    <span>输出: <b style={{ color: 'var(--text-primary)' }}>${price.output}</b></span>
                    {price.cacheHit !== undefined && (
                      <span>缓存命中: <b style={{ color: '#10B981' }}>${price.cacheHit}</b></span>
                    )}
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      ))}
    </div>
  )
}
