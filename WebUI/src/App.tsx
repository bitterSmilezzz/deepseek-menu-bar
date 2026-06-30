import { useEffect, Component, ReactNode } from 'react'
import { useAppStore } from './stores/appStore'
import { useBridge } from './hooks/useBridge'
import Dashboard from './components/Dashboard'
import ProxyControl from './components/ProxyControl'
import UsageStats from './components/UsageStats'
import PricingList from './components/PricingList'
import UsageHistory from './components/UsageHistory'
import AddKey from './components/AddKey'
import Settings from './components/Settings'

class ErrorBoundary extends Component<{ children: ReactNode }, { hasError: boolean; error: string }> {
  constructor(props: { children: ReactNode }) { super(props); this.state = { hasError: false, error: '' } }
  static getDerivedStateFromError(error: Error) { return { hasError: true, error: error.message } }
  render() {
    if (this.state.hasError) {
      return (
        <div className="p-4 text-center" style={{ color: 'var(--text-secondary)' }}>
          <div className="text-2xl mb-2">⚠️</div>
          <div className="text-sm font-medium mb-1">渲染错误</div>
          <div className="text-xs" style={{ color: 'var(--text-muted)' }}>{this.state.error}</div>
        </div>
      )
    }
    return this.props.children
  }
}

export default function App() {
  const { theme, currentPage } = useAppStore()
  const { callNative } = useBridge()

  useEffect(() => {
    const root = document.documentElement
    theme === 'light' ? root.classList.add('light') : root.classList.remove('light')
  }, [theme])

  function renderPage() {
    const setPage = useAppStore.getState().setPage
    switch (currentPage) {
      case 'dashboard': return <Dashboard onNavigate={setPage} />
      case 'proxy': return <ProxyControl onBack={() => setPage('dashboard')} />
      case 'stats': return <UsageStats onBack={() => setPage('dashboard')} />
      case 'pricing': return <PricingList onBack={() => setPage('dashboard')} />
      case 'history': return <UsageHistory onBack={() => setPage('dashboard')} />
      case 'addkey': return <AddKey onBack={() => setPage('settings')} callNative={callNative} />
      case 'settings': return <Settings onNavigate={setPage} callNative={callNative} />
      default: return null
    }
  }

  return (
    <ErrorBoundary>
      <div className="w-[370px] max-h-[520px] overflow-y-auto"
        style={{
          background: 'var(--bg-secondary)',
          backdropFilter: 'blur(40px)',
          borderRadius: '18px',
        }}>
        <div className="p-4 animate-[popIn_0.2s_ease-out]">
          {renderPage()}
        </div>
      </div>
    </ErrorBoundary>
  )
}
