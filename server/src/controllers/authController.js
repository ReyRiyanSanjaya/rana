const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const { successResponse, errorResponse } = require('../utils/response');

const SECRET_KEY = process.env.JWT_SECRET || 'super_secret_key_change_in_prod';

// REGISTER (Onboarding Tenant)
const register = async (req, res) => {
    try {
        const { businessName, email, password, role, waNumber, latitude, longitude, address, category } = req.body;

        // 1. Check if user exists
        const existingUser = await prisma.user.findUnique({ where: { email } });
        if (existingUser) return errorResponse(res, "Email already exists", 400);

        // 2. Hash Password
        const hashedPassword = await bcrypt.hash(password, 10);

        // 3. Transaction: Create Tenant + User + Default Store (with Loc)
        const result = await prisma.$transaction(async (tx) => {
            const tenant = await tx.tenant.create({
                data: { name: businessName, plan: 'FREE' }
            });

            const user = await tx.user.create({
                data: {
                    email,
                    passwordHash: hashedPassword,
                    name: businessName + ' Owner',
                    role: role || 'OWNER',
                    tenant: { connect: { id: tenant.id } }
                }
            });

            // Create Default Store with Captured Location & WA
            const store = await tx.store.create({
                data: {
                    tenantId: tenant.id,
                    name: businessName, // Changed from 'Pusat'
                    waNumber: waNumber,
                    address: address, // Changed from 'location' to 'address'
                    category: category, // [NEW] Save Category
                    latitude: latitude ? parseFloat(latitude) : null, // [NEW] Save Location
                    longitude: longitude ? parseFloat(longitude) : null // [NEW] Save Location
                }
            });

            return { tenant, user };
        });

        return successResponse(res, { tenantId: result.tenant.id, email: result.user.email }, "Registration Successful");

    } catch (error) {
        return errorResponse(res, "Registration Failed", 500, error);
    }
};

// LOGIN
const login = async (req, res) => {
    try {
        const { email, password } = req.body;

        const user = await prisma.user.findUnique({ where: { email } });
        if (!user) return errorResponse(res, "Invalid User", 401);

        const validPass = await bcrypt.compare(password, user.passwordHash);
        if (!validPass) return errorResponse(res, "Invalid Password", 401);

        // Fetch Primary Store for this Tenant (Assuming 1 Store per Tenant for current MVP)
        const store = await prisma.store.findFirst({
            where: { tenantId: user.tenantId }
        });

        // Generate Token
        const token = jwt.sign(
            {
                userId: user.id,
                tenantId: user.tenantId,
                role: user.role,
                storeId: store ? store.id : null // [NEW] Include StoreId
            },
            SECRET_KEY,
            { expiresIn: '30d' }
        );

        return successResponse(res, {
            token,
            user: {
                id: user.id,
                name: user.name,
                role: user.role,
                tenantId: user.tenantId,
                storeId: store ? store.id : null // [NEW] Return to client too
            }
        }, "Login Successful");

    } catch (error) {
        return errorResponse(res, "Login Failed", 500, error);
    }
};

module.exports = { register, login };
