export function getToken() {
    try {
        return localStorage.getItem('adminToken') || null
    } catch {
        return null
    }
}

function base64UrlDecode(input) {
    try {
        const base64 = input.replace(/-/g, '+').replace(/_/g, '/')
        const pad = base64.length % 4 === 0 ? '' : '='.repeat(4 - (base64.length % 4))
        const str = atob(base64 + pad)
        let result = ''
        for (let i = 0; i < str.length; i++) {
            result += String.fromCharCode(str.charCodeAt(i))
        }
        return result
    } catch {
        return ''
    }
}

export function parseJwt(token) {
    try {
        const parts = token.split('.')
        if (parts.length !== 3) return null
        const payload = JSON.parse(base64UrlDecode(parts[1]))
        return payload
    } catch {
        return null
    }
}

export function isTokenExpired() {
    const token = getToken()
    if (!token) return true
    const payload = parseJwt(token)
    if (!payload || !payload.exp) return true
    const now = Math.floor(Date.now() / 1000)
    return payload.exp <= now
}

export function getUser() {
    try {
        const raw = localStorage.getItem('adminUser')
        if (!raw) return null
        return JSON.parse(raw)
    } catch {
        return null
    }
}

export function getRole() {
    const user = getUser()
    return user && user.role ? user.role : null
}

export function logout() {
    try {
        localStorage.removeItem('adminToken')
        localStorage.removeItem('adminUser')
    } finally {
        window.location.href = '/login'
    }
}
