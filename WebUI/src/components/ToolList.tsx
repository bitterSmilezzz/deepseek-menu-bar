import { useAppStore } from '../stores/appStore'

interface ToolListProps {
  onBack: () => void
}

export default function ToolList({ onBack }: ToolListProps) {
  const { tools } = useAppStore()

  return (
    <div className="space-y-3">
      <button onClick={onBack} className="flex items-center gap-1.5 text-xs transition-all duration-200 hover:opacity-70" style={{ color: 'var(--btn-text)' }}>
        ← 返回
      </button>

      <div className="text-sm font-semibold" style={{ color: 'var(--text-primary)' }}>工具列表</div>

      <div className="space-y-1">
        {tools.map((tool) => (
          <div
            key={tool.id}
            className="flex items-center gap-3 rounded-xl p-3 border transition-all duration-200"
            style={{ background: 'var(--card-bg)', borderColor: 'var(--card-border)' }}
          >
            <span className="text-lg">{tool.icon}</span>
            <div className="flex-1 min-w-0">
              <div className="text-sm font-medium" style={{ color: 'var(--text-primary)' }}>{tool.name}</div>
              <div className="text-[11px] truncate" style={{ color: 'var(--text-tertiary)' }}>{tool.description}</div>
            </div>
            <span className="text-[10px] px-2 py-0.5 rounded-full" style={{ background: 'var(--card-hover)', color: 'var(--text-tertiary)' }}>
              {tool.category}
            </span>
          </div>
        ))}
      </div>

      {tools.length === 0 && (
        <div className="text-center py-8 text-sm" style={{ color: 'var(--text-muted)' }}>
          暂无工具数据
        </div>
      )}
    </div>
  )
}
