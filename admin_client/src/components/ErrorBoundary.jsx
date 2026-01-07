import React, { Component } from 'react'

class ErrorBoundary extends Component {
  constructor(props) {
    super(props)
    this.state = { hasError: false, error: null }
  }

  static getDerivedStateFromError(error) {
    return { hasError: true, error }
  }

  componentDidCatch(error, info) {
    console.error('ErrorBoundary caught', error, info)
  }

  render() {
    if (this.state.hasError) {
      return (
        <div className="min-h-screen flex items-center justify-center bg-slate-50">
          <div className="max-w-md w-full bg-white border border-slate-200 rounded-xl shadow-sm p-6 text-center">
            <h2 className="text-lg font-semibold text-slate-900">Terjadi kesalahan</h2>
            <p className="mt-2 text-sm text-slate-600">Silakan muat ulang halaman atau kembali beberapa saat lagi.</p>
            <button
              className="mt-4 inline-flex items-center justify-center rounded-xl bg-primary-200 text-primary-900 px-4 py-2 text-sm font-medium hover:bg-primary-300"
              onClick={() => {
                this.setState({ hasError: false, error: null })
                window.location.reload()
              }}
            >
              Muat Ulang
            </button>
          </div>
        </div>
      )
    }
    return this.props.children
  }
}

export default ErrorBoundary
