import { io } from 'socket.io-client';
import { getToken } from './auth';

let socket;

export const initSocket = () => {
    if (socket && socket.connected) return socket;

    const token = getToken();
    if (!token) return null;

    const SOCKET_URL = import.meta.env.VITE_API_URL 
        ? import.meta.env.VITE_API_URL.replace('/api', '') 
        : 'http://localhost:4000';

    // Prevent multiple instances if called rapidly
    if (socket) {
        socket.disconnect();
    }

    socket = io(SOCKET_URL, {
        auth: { token },
        transports: ['websocket'],
        reconnection: true,
        reconnectionAttempts: 5,
        reconnectionDelay: 1000,
    });

    socket.on('connect', () => {
        console.log('Socket connected:', socket.id);
    });

    socket.on('connect_error', (err) => {
        console.error('Socket connection error:', err);
    });

    return socket;
};

export const getSocket = () => {
    if (!socket) return initSocket();
    return socket;
};

export const disconnectSocket = () => {
    if (socket) {
        socket.disconnect();
        socket = null;
    }
};
