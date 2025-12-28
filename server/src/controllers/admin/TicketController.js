const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
const { getIo } = require('../../socket');

const getTickets = async (req, res) => {
    try {
        const { status, tenantId } = req.query;
        const where = {};
        if (status) where.status = status;
        if (tenantId) where.tenantId = tenantId;

        const tickets = await prisma.supportTicket.findMany({
            where,
            include: {
                tenant: {
                    select: { name: true } // Tenant has no email directly
                },
                _count: { select: { messages: true } }
            },
            orderBy: { updatedAt: 'desc' }
        });

        res.json({ success: true, data: tickets });
    } catch (error) {
        console.error(error);
        res.status(500).json({ success: false, message: "Error fetching tickets" });
    }
};

const getTicketDetail = async (req, res) => {
    try {
        const { id } = req.params;
        const ticket = await prisma.supportTicket.findUnique({
            where: { id },
            include: {
                tenant: {
                    select: { name: true, id: true }
                },
                messages: {
                    orderBy: { createdAt: 'asc' }
                }
            }
        });

        if (!ticket) return res.status(404).json({ success: false, message: "Ticket not found" });

        res.json({ success: true, data: ticket });
    } catch (error) {
        res.status(500).json({ success: false, message: "Error fetching ticket detail" });
    }
};

const replyTicket = async (req, res) => {
    try {
        const { id } = req.params;
        const { message } = req.body;
        // req.user is populated by auth middleware, assuming Admin
        const userId = req.user?.id || "ADMIN";

        const newMessage = await prisma.ticketMessage.create({
            data: {
                ticketId: id,
                senderType: 'ADMIN',
                senderId: userId,
                message,
                isAdmin: true
            }
        });

        // Auto-update status to IN_PROGRESS if currently OPEN
        await prisma.supportTicket.update({
            where: { id },
            data: { status: 'IN_PROGRESS', updatedAt: new Date() }
        });

        // Emit Socket Event
        try {
            getIo().to(id).emit('new_message', newMessage);
        } catch (e) {
            console.error("Socket emit failed", e);
        }

        res.json({ success: true, data: newMessage });
    } catch (error) {
        console.error(error);
        res.status(500).json({ success: false, message: "Error replying to ticket" });
    }
};

const updateStatus = async (req, res) => {
    try {
        const { id } = req.params;
        const { status } = req.body; // RESOLVED, CLOSED, etc.

        await prisma.supportTicket.update({
            where: { id },
            data: { status }
        });

        res.json({ success: true, message: "Status updated" });
    } catch (error) {
        res.status(500).json({ success: false, message: "Error updating status" });
    }
};

module.exports = {
    getTickets,
    getTicketDetail,
    replyTicket,
    updateStatus
};
