import { useEffect, useState, Component, ReactNode } from 'react'
import { useAppStore } from './stores/appStore'
import { useBridge } from './hooks/useBridge'
import Dashboard from './components/Dashboard'
import AddKey from './components/AddKey'
import ToolList from './components/ToolList'
import NewsFeed from './components/NewsFeed'
import Settings from './components/Settings'
import type { Balance, Usage, Tool, ApiKey } from './types'

class ErrorBoundary extends Component<{children: ReactNode}, {hasError: boolean, error: string}> {
  constructor(props: {children: ReactNode}) {
    super(props)
    this.state = { hasError: false, error: '' }
  }
  static getDerivedStateFromError(error: Error) {
    return { hasError: true, error: error.message }
  }
  render() {
    if (this.state.hasError) {
      return (
        <div className="p-4 text-center" style={{color: 'var(--text-secondary)'}}>
          <div className="text-2xl mb-2">⚠️</div>
          <div className="text-sm font-medium mb-1">Render Error</div>
          <div className="text-xs" style={{color: 'var(--text-muted)'}}>{this.state.error}</div>
        </div>
      )
    }
    return this.props.children
  }
}

export default function App() {
  const { theme, currentPage, setBalance, setUsage, setTools, setApiKeys, setError } = useAppStore()
  const { callNative } = useBridge()

  useEffect(() => {
    console.log('[DeepSeek] React mounted, isNative:', callNative !== undefined)
  }, [])

  useEffect(() => {
    const root = document.documentElement
    if (theme === 'light') {
      root.classList.add('light')
    } else {
      root.classList.remove('light')
    }
  }, [theme])

  useEffect(() => {
    loadData()
  }, [])

  async function loadData() {
    try {
      const keys = await callNative<ApiKey[]>('getApiKeys').catch(() => [])
      const balance = await callNative<Balance>('getBalance').catch(() => null)
      const usage = await callNative<Usage>('getUsage').catch(() => null)
      const tools = await callNative<any>('getTools').catch(() => [])

      if (Array.isArray(keys)) setApiKeys(keys)
      if (balance) setBalance(balance)
      if (usage) setUsage(usage)
      if (Array.isArray(tools)) setTools(tools)
    } catch (e: any) {
      console.warn('[DeepSeek] loadData error:', e)
      setError(e.message)
    }
  }

  function renderPage() {
    switch (currentPage) {
      case 'dashboard': return <Dashboard onNavigate={(p) => useAppStore.getState().setPage(p)} />
      case 'addkey': return <AddKey onBack={() => useAppStore.getState().setPage('dashboard')} callNative={callNative} />
      case 'tools': return <ToolList onBack={() => useAppStore.getState().setPage('dashboard')} />
      case 'news': return <NewsFeed onBack={() => useAppStore.getState().setPage('dashboard')} callNative={callNative} />
      case 'settings': return <Settings onNavigate={(p) => useAppStore.getState().setPage(p)} callNative={callNative} />
      default: return null
    }
  }

  return (
    <ErrorBoundary>
      <div className="w-[370px] max-h-[520px] overflow-y-auto" style={{ background: 'var(--bg-secondary)', backdropFilter: 'blur(40px)', borderRadius: '18px' }}>
        <div className="p-4 animate-[popIn_0.2s_ease-out]">
          {renderPage()}
        </div>
      </div>
    </ErrorBoundary>
  )
}
