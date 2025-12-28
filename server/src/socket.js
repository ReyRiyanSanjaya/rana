const socketIo = require('socket.io');
const jwt = require('jsonwebtoken');

let io;

const initSocket = (server) => {
    io = socketIo(server, {
        cors: {
            origin: "*", // Allow all for now
            methods: ["GET", "POST"]
        }
    });

    // [DEBUG] Log all connection attempts
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

        // Send Message (Directly via Socket or just Notification?)
        // Let's support both. If client sends 'send_message', we can save to DB and emit. 
        // But to keep consistency with existing logic, we might just listen for REST API triggers from Controller
        // For now, let's just handle Typing.

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

module.exports = { initSocket, getIo };
