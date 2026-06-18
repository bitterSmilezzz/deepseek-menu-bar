import { useEffect } from 'react'
import { useAppStore } from './stores/appStore'
import { useBridge } from './hooks/useBridge'
import Dashboard from './components/Dashboard'
import AddKey from './components/AddKey'
import ToolList from './components/ToolList'
import NewsFeed from './components/NewsFeed'
import Settings from './components/Settings'
import type { Balance, Usage, Tool, ApiKey } from './types'

export default function App() {
  const { theme, currentPage, setBalance, setUsage, setTools, setApiKeys, setError } = useAppStore()
  const { callNative } = useBridge()

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
      const [keys, balance, usage, tools] = await Promise.all([
        callNative<ApiKey[]>('getApiKeys'),
        callNative<Balance>('getBalance'),
        callNative<Usage>('getUsage'),
        callNative<Tool[]>('getTools'),
      ])
      if (keys) setApiKeys(keys)
      if (balance) setBalance(balance)
      if (usage) setUsage(usage)
      if (tools) setTools(tools)
    } catch (e: any) {
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
    <div className="w-[370px] max-h-[520px] overflow-y-auto" style={{ background: 'var(--bg-secondary)', backdropFilter: 'blur(40px)', borderRadius: '18px' }}>
      <div className="p-4 animate-[popIn_0.2s_ease-out]">
        {renderPage()}
      </div>
    </div>
  )
}
