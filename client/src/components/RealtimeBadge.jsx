import React, { useEffect, useState } from 'react'
import { initTransactionsStream, subscribeTransactions } from '../services/transactionsStream'

const formatTime = (iso) => {
  if (!iso) return '-'
  try {
    const d = new Date(iso)
    return d.toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit', second: '2-digit' })
  } catch { return '-' }
}

const RealtimeBadge = () => {
  const [state, setState] = useState({ connected: false, lastSync: null })
  useEffect(() => {
    initTransactionsStream()
    const unsub = subscribeTransactions((s) => setState({ connected: s.connected, lastSync: s.lastSync }))
    return () => unsub()
  }, [])
  return (
    <div className={`inline-flex items-center px-3 py-1.5 rounded-full text-xs ${state.connected ? 'bg-green-100 text-green-700' : 'bg-slate-100 text-slate-700'}`}>
      <span className={`w-2 h-2 rounded-full mr-2 ${state.connected ? 'bg-green-500' : 'bg-slate-400'}`}></span>
      <span className="mr-2">{state.connected ? 'Realtime Connected' : 'Offline'}</span>
      <span className="text-slate-500">Last Sync: {formatTime(state.lastSync)}</span>
    </div>
  )
}

export default RealtimeBadge
