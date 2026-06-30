import { useState, useEffect } from 'react'
import { useAppStore } from '../stores/appStore'
import { useBridge } from '../hooks/useBridge'
import { Line, Pie, Bar } from 'react-chartjs-2'
import {
  Chart as ChartJS, CategoryScale, LinearScale, PointElement,
  LineElement, BarElement, ArcElement, Title, Tooltip, Legend, Filler
} from 'chart.js'

ChartJS.register(CategoryScale, LinearScale, PointElement, LineElement,
  BarElement, ArcElement, Title, Tooltip, Legend, Filler)

const chartColors = ['#3B82F6', '#8B5CF6', '#10B981', '#F59E0B', '#EF4444',
  '#EC4899', '#6366F1', '#14B8A6', '#F97316', '#84CC16']

interface Props { onBack: () => void }

export default function UsageStats({ onBack }: Props) {
  const { recentStats, todayStats, setRecentStats, setTodayStats } = useAppStore()
  const { callNative } = useBridge()
  const [view, setView] = useState<'tokens' | 'cost'>('tokens')

  useEffect(() => {
    const load = async () => {
      const stats = await callNative<any[]>('getRecentStats')
      if (stats) setRecentStats(stats)
      const today = await callNative<any>('getTodayStats')
      if (today) setTodayStats(today)
    }
    load()
  }, [])

  const lineData = {
    labels: recentStats.map(s => s.date.slice(5)),
    datasets: [
      {
        label: view === 'tokens' ? 'Tokens' : '费用 (¥)',
        data: recentStats.map(s => view === 'tokens' ? s.totalInputTokens + s.totalOutputTokens : s.totalCostRMB),
        borderColor: '#3B82F6',
        backgroundColor: 'rgba(59,130,246,0.1)',
        fill: true,
        tension: 0.3,
        pointRadius: 3,
        pointHoverRadius: 5,
      },
    ],
  }

  const pieData = {
    labels: todayStats ? Object.keys(todayStats.modelBreakdown) : [],
    datasets: [{
      data: todayStats ? Object.values(todayStats.modelBreakdown).map(m => m.inputTokens + m.outputTokens) : [],
      backgroundColor: chartColors,
      borderWidth: 0,
    }],
  }

  const barData = {
    labels: recentStats.map(s => s.date.slice(5)),
    datasets: [
      {
        label: '¥ RMB',
        data: recentStats.map(s => s.totalCostRMB),
        backgroundColor: '#8B5CF6',
        borderRadius: 6,
      },
      {
        label: '$ USD',
        data: recentStats.map(s => s.totalCostUSD),
        backgroundColor: '#3B82F6',
        borderRadius: 6,
      },
    ],
  }

  return (
    <div className="space-y-4">
      <button onClick={onBack} className="flex items-center gap-1.5 text-xs" style={{ color: 'var(--btn-text)' }}>← 返回</button>

      <div className="text-sm font-semibold" style={{ color: 'var(--text-primary)' }}>用量统计</div>

      <div className="flex gap-2">
        <button onClick={() => setView('tokens')}
          className="text-xs px-3 py-1.5 rounded-lg transition"
          style={{
            background: view === 'tokens' ? 'linear-gradient(135deg,#3B82F6,#8B5CF6)' : 'var(--card-bg)',
            color: view === 'tokens' ? '#fff' : 'var(--text-tertiary)'
          }}>Tokens</button>
        <button onClick={() => setView('cost')}
          className="text-xs px-3 py-1.5 rounded-lg transition"
          style={{
            background: view === 'cost' ? 'linear-gradient(135deg,#3B82F6,#8B5CF6)' : 'var(--card-bg)',
            color: view === 'cost' ? '#fff' : 'var(--text-tertiary)'
          }}>费用</button>
      </div>

      <div className="rounded-xl p-3 border" style={{ background: 'var(--card-bg)', borderColor: 'var(--card-border)' }}>
        <div className="text-xs font-medium mb-2" style={{ color: 'var(--text-tertiary)' }}>📈 7 日趋势</div>
        <Line data={lineData} options={{
          responsive: true,
          plugins: { legend: { display: false } },
          scales: {
            x: { ticks: { color: 'rgba(255,255,255,0.3)', font: { size: 10 } }, grid: { display: false } },
            y: { ticks: { color: 'rgba(255,255,255,0.3)', font: { size: 10 } }, grid: { color: 'rgba(255,255,255,0.05)' } },
          },
        }} />
      </div>

      <div className="grid grid-cols-2 gap-3">
        <div className="rounded-xl p-3 border" style={{ background: 'var(--card-bg)', borderColor: 'var(--card-border)' }}>
          <div className="text-xs font-medium mb-2" style={{ color: 'var(--text-tertiary)' }}>🍩 模型分布</div>
          <Pie data={pieData} options={{
            responsive: true,
            plugins: { legend: { display: true, position: 'bottom', labels: { color: 'rgba(255,255,255,0.5)', font: { size: 9 }, padding: 8 } } },
          }} />
        </div>

        <div className="rounded-xl p-3 border" style={{ background: 'var(--card-bg)', borderColor: 'var(--card-border)' }}>
          <div className="text-xs font-medium mb-2" style={{ color: 'var(--text-tertiary)' }}>📊 费用对比</div>
          <Bar data={barData} options={{
            responsive: true,
            plugins: { legend: { display: true, position: 'bottom', labels: { color: 'rgba(255,255,255,0.5)', font: { size: 9 }, padding: 8, boxWidth: 10 } } },
            scales: {
              x: { ticks: { color: 'rgba(255,255,255,0.3)', font: { size: 9 } }, grid: { display: false } },
              y: { ticks: { color: 'rgba(255,255,255,0.3)', font: { size: 9 } }, grid: { color: 'rgba(255,255,255,0.05)' } },
            },
          }} />
        </div>
      </div>
    </div>
  )
}
