import { io } from 'socket.io-client'
import api, { fetchTransactionHistory } from './api'

let socket = null
let connected = false
let listeners = []
let list = []
let lastSync = null
let recentEventAt = null

const emit = () => {
  for (const l of listeners) {
    try { l({ connected, list, lastSync, recentEventAt }) } catch {}
  }
}

export const initTransactionsStream = async () => {
  const token = localStorage.getItem('token')
  const baseUrl = api?.defaults?.baseURL || ''
  const socketUrl = baseUrl ? baseUrl.replace(/\/api\/?$/, '') : 'http://localhost:4000'
  if (!token) return
  if (socket) return
  try {
    const data = await fetchTransactionHistory()
    list = Array.isArray(data) ? data : []
    lastSync = new Date().toISOString()
    emit()
  } catch {}
  socket = io(socketUrl, { auth: { token }, transports: ['websocket', 'polling'] })
  socket.on('connect', () => { connected = true; lastSync = new Date().toISOString(); emit() })
  socket.on('disconnect', () => { connected = false; emit() })
  socket.on('transactions:created', async (payload) => {
    if (payload && typeof payload === 'object') {
      list = [payload, ...list].slice(0, 200)
      lastSync = new Date().toISOString()
      recentEventAt = lastSync
      emit()
    } else {
      try {
        const data = await fetchTransactionHistory()
        list = Array.isArray(data) ? data : list
        lastSync = new Date().toISOString()
        recentEventAt = lastSync
        emit()
      } catch {}
    }
  })
}

export const subscribeTransactions = (fn) => {
  listeners.push(fn)
  fn({ connected, list })
  return () => {
    listeners = listeners.filter((x) => x !== fn)
  }
}

export const disconnectTransactionsStream = () => {
  try { socket?.disconnect() } catch {}
  socket = null
  connected = false
  emit()
}
