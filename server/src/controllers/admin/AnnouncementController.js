const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

const getAnnouncements = async (req, res) => {
    try {
        const items = await prisma.announcement.findMany({
            orderBy: { createdAt: 'desc' }
        });
        res.json({ success: true, data: items });
    } catch (error) {
        res.status(500).json({ success: false, message: "Error fetching announcements" });
    }
};

const createAnnouncement = async (req, res) => {
    try {
        const { title, content, isActive } = req.body;
        const newItem = await prisma.announcement.create({
            data: {
                title,
                content,
                isActive: isActive !== undefined ? isActive : true
            }
        });
        res.json({ success: true, data: newItem });
    } catch (error) {
        res.status(500).json({ success: false, message: "Error creating announcement" });
    }
};

const deleteAnnouncement = async (req, res) => {
    try {
        const { id } = req.params;
        await prisma.announcement.delete({ where: { id } });
        res.json({ success: true, message: "Deleted successfully" });
    } catch (error) {
        res.status(500).json({ success: false, message: "Error deleting announcement" });
    }
};

const toggleActive = async (req, res) => {
    try {
        const { id } = req.params;
        const { isActive } = req.body;
        const item = await prisma.announcement.update({
            where: { id },
            data: { isActive }
        });
        res.json({ success: true, data: item });
    } catch (error) {
        res.status(500).json({ success: false, message: "Error updating status" });
    }
};

module.exports = {
    getAnnouncements,
    createAnnouncement,
    deleteAnnouncement,
    toggleActive
};
