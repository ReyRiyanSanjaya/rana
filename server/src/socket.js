const socketIo = require('socket.io');
const jwt = require('jsonwebtoken');
const { PrismaClient } = require('@prisma/client');

let io;
const prisma = new PrismaClient();

const initSocket = (server) => {
    io = socketIo(server, {
        cors: {
            origin: "*", // Allow all for now
            methods: ["GET", "POST"]
        }
    });

    io.engine.on("connection_error", (err) => {
        console.log("Socket Connection Error:", err.req.url, err.code, err.message, err.context);
    });

    io.use((socket, next) => {
        console.log("Socket Auth Attempt:", socket.id, "Token provided?", !!socket.handshake.auth.token);
        const token = socket.handshake.auth.token;
        if (!token) {
            console.log("Socket Auth Failed: No Token");
            return next(new Error('Authentication error'));
        }

        try {
            const decoded = jwt.verify(token, process.env.JWT_SECRET || 'super_secret_key_change_in_prod');
            socket.user = decoded;
            console.log("Socket Auth Success:", socket.user.role, socket.user.userId);
            next();
        } catch (e) {
            console.log("Socket Auth Failed: Invalid Token", e.message);
            next(new Error('Authentication error'));
        }
    });

    io.on('connection', (socket) => {
        console.log('User connected:', socket.user.role, socket.user.userId);
        if (socket.user?.tenantId) socket.join(`tenant:${socket.user.tenantId}`);
        if (socket.user?.storeId) socket.join(`store:${socket.user.storeId}`);

        // Join Ticket Room
        socket.on('join_ticket', (ticketId) => {
            socket.join(ticketId);
            console.log(`User ${socket.user.userId} joined ticket ${ticketId}`);
        });

        // Typing Indicators
        socket.on('typing', ({ ticketId, isTyping }) => {
            // Broadcast to everyone in room EXCEPT sender
            socket.to(ticketId).emit('typing', {
                userId: socket.user.userId,
                role: socket.user.role, // 'ADMIN' or 'OWNER'/'CASHIER'
                isTyping
            });
        });

        socket.on('send_message', async ({ ticketId, message }) => {
            try {
                if (!ticketId || !message || typeof message !== 'string' || !message.trim()) {
                    return;
                }

                const where = { id: ticketId };
                if (socket.user.role !== 'ADMIN' && socket.user.tenantId) {
                    where.tenantId = socket.user.tenantId;
                }

                const ticket = await prisma.supportTicket.findFirst({ where });
                if (!ticket) return;

                const isAdmin = socket.user.role === 'ADMIN';
                const senderType = isAdmin ? 'ADMIN' : 'MERCHANT';

                const newMessage = await prisma.ticketMessage.create({
                    data: {
                        ticketId,
                        message: message.trim(),
                        senderId: socket.user.userId,
                        senderType,
                        isAdmin
                    }
                });

                if (!isAdmin && ticket.status === 'RESOLVED') {
                    await prisma.supportTicket.update({
                        where: { id: ticketId },
                        data: { status: 'OPEN' }
                    });
                }

                io.to(ticketId).emit('new_message', newMessage);
            } catch (e) {
                console.error('send_message error', e);
            }
        });

        socket.on('disconnect', () => {
            console.log('User disconnected');
        });
    });
};

const getIo = () => {
    if (!io) {
        throw new Error("Socket.io not initialized!");
    }
    return io;
};

const emitToTenant = (tenantId, event, payload) => {
    try {
        if (!io) return;
        io.to(`tenant:${tenantId}`).emit(event, payload);
    } catch (e) {
        console.error("emitToTenant failed", e);
    }
};

module.exports = { initSocket, getIo, emitToTenant };
