import React, { useEffect, useState, useRef } from 'react'
import DashboardLayout from '../components/layout/DashboardLayout'
import { initTransactionsStream, subscribeTransactions } from '../services/transactionsStream'

const Badge = ({ connected }) => (
  <span className={`inline-flex items-center px-2 py-1 rounded-full text-xs ${connected ? 'bg-green-100 text-green-700' : 'bg-slate-100 text-slate-600'}`}>
    <span className={`w-2 h-2 rounded-full mr-2 ${connected ? 'bg-green-500' : 'bg-slate-400'}`}></span>
    {connected ? 'Realtime Connected' : 'Offline'}
  </span>
)

const formatCurrency = (val) =>
  new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR' }).format(val || 0)

const formatTime = (iso) => {
  try { return new Date(iso).toLocaleString('id-ID') } catch { return '' }
}

const Transactions = () => {
  const [state, setState] = useState({ connected: false, list: [], recentEventAt: null })
  const [updating, setUpdating] = useState(false)
  const lastEventRef = useRef(null)

  useEffect(() => {
    initTransactionsStream()
    const unsub = subscribeTransactions((s) => {
      setState(s)
      if (s.recentEventAt && s.recentEventAt !== lastEventRef.current) {
        lastEventRef.current = s.recentEventAt
        setUpdating(true)
        setTimeout(() => setUpdating(false), 1500)
      }
    })
    return () => unsub()
  }, [])

  return (
    <DashboardLayout>
      <div className="space-y-6">
        <div className="flex items-center justify-between">
          <div>
            <h2 className="text-2xl font-bold text-slate-900">Transaksi</h2>
            <p className="text-slate-500">Data realtime dari kasir</p>
          </div>
          <Badge connected={state.connected} />
        </div>

        <div className="bg-white rounded-xl shadow-sm border border-slate-100">
          <div className="p-4 border-b border-slate-100 flex items-center justify-between">
            <span className="text-sm text-slate-600">Total: {state.list.length}</span>
            {updating && (
              <div className="flex items-center text-primary-600">
                <span className="animate-spin rounded-full h-4 w-4 border-b-2 border-primary-600 mr-2"></span>
                <span className="text-sm">Updating...</span>
              </div>
            )}
          </div>
          <div className="overflow-x-auto">
            <table className="min-w-full">
              <thead>
                <tr className="bg-slate-50 text-slate-600 text-sm">
                  <th className="text-left px-4 py-3">Waktu</th>
                  <th className="text-left px-4 py-3">Kasir</th>
                  <th className="text-left px-4 py-3">Metode</th>
                  <th className="text-right px-4 py-3">Total</th>
                </tr>
              </thead>
              <tbody>
                {state.list.map((t, i) => (
                  <tr key={(t.id || t.offlineId || i) + '-' + i} className={`border-t border-slate-100 ${updating && i === 0 ? 'bg-green-50 transition-colors' : ''}`}>
                    <td className="px-4 py-3 text-slate-800">{formatTime(t.createdAt || t.occurredAt)}</td>
                    <td className="px-4 py-3 text-slate-800">{t.cashierName || t.cashierId || '-'}</td>
                    <td className="px-4 py-3">
                      <span className="px-2 py-1 rounded-full text-xs bg-indigo-100 text-indigo-700">{(t.paymentMethod || 'CASH').toString()}</span>
                    </td>
                    <td className="px-4 py-3 text-right font-semibold">{formatCurrency(t.totalAmount)}</td>
                  </tr>
                ))}
                {state.list.length === 0 && (
                  <tr>
                    <td colSpan={4} className="px-4 py-10 text-center text-slate-500">Belum ada data transaksi</td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </DashboardLayout>
  )
}

export default Transactions
