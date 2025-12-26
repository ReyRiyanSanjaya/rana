const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
const { successResponse, errorResponse } = require('../utils/response');

const getMyTickets = async (req, res) => {
    try {
        const { tenantId } = req.user; // Assuming merchant has tenantId in token
        const tickets = await prisma.supportTicket.findMany({
            where: { tenantId },
            orderBy: { updatedAt: 'desc' }
        });
        successResponse(res, tickets);
    } catch (error) {
        errorResponse(res, "Failed to fetch tickets", 500);
    }
};

const createTicket = async (req, res) => {
    try {
        const { tenantId } = req.user;
        const { subject, message, priority } = req.body;

        const ticket = await prisma.supportTicket.create({
            data: {
                tenantId,
                subject,
                priority: priority || 'NORMAL',
                status: 'OPEN',
                messages: {
                    create: {
                        message,
                        senderType: 'MERCHANT',
                        isAdmin: false
                    }
                }
            }
        });
        successResponse(res, ticket, "Ticket created");
    } catch (error) {
        errorResponse(res, "Failed to create ticket", 500, error);
    }
};

const getTicketDetail = async (req, res) => {
    try {
        const { id } = req.params;
        const { tenantId } = req.user;
        const ticket = await prisma.supportTicket.findFirst({
            where: { id, tenantId }, // Ensure ownership
            include: { messages: { orderBy: { createdAt: 'asc' } } }
        });
        if (!ticket) return errorResponse(res, "Ticket not found", 404);
        successResponse(res, ticket);
    } catch (error) {
        errorResponse(res, "Error fetching ticket", 500);
    }
};

const replyTicket = async (req, res) => {
    try {
        const { id } = req.params;
        const { tenantId } = req.user;
        const { message } = req.body;

        const ticket = await prisma.supportTicket.findFirst({ where: { id, tenantId } });
        if (!ticket) return errorResponse(res, "Ticket not found", 404);

        const newMessage = await prisma.ticketMessage.create({
            data: {
                ticketId: id,
                message,
                senderType: 'MERCHANT',
                isAdmin: false
            }
        });

        // Auto update status if resolved/closed? Maybe not.
        // But invalidating 'RESOLVED' status might be good if merchant replies.
        if (ticket.status === 'RESOLVED') {
            await prisma.supportTicket.update({ where: { id }, data: { status: 'OPEN' } });
        }

        successResponse(res, newMessage);
    } catch (error) {
        errorResponse(res, "Reply failed", 500);
    }
};

module.exports = { getMyTickets, createTicket, getTicketDetail, replyTicket };
