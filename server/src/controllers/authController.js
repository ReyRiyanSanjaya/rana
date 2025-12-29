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
                    location: address, // Map 'address' input to 'location' field in DB
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

// [NEW] Update Store Profile (Mobile)
const updateStoreProfile = async (req, res) => {
    try {
        const { tenantId } = req.user;
        const { businessName, waNumber, address, latitude, longitude } = req.body;

        // Update Tenant Info
        await prisma.tenant.update({
            where: { id: tenantId },
            data: {
                name: businessName,
                phoneNumber: waNumber
            }
        });

        // Update Store Info (Assuming data for primary store)
        // Find store by tenantId
        const store = await prisma.store.findFirst({ where: { tenantId } });
        if (store) {
            await prisma.store.update({
                where: { id: store.id },
                data: {
                    location: address,
                    latitude: latitude ? parseFloat(latitude) : undefined,
                    longitude: longitude ? parseFloat(longitude) : undefined
                }
            });
        }

        successResponse(res, null, "Profile updated successfully");
    } catch (error) {
        errorResponse(res, "Failed to update profile", 500, error);
    }
};

const getProfile = async (req, res) => {
    try {
        const { userId } = req.user; // [FIX] Use userId from token
        const user = await prisma.user.findUnique({
            where: { id: userId },
            select: {
                id: true,
                name: true,
                email: true,
                role: true,
                createdAt: true,
                tenant: {
                    select: { id: true, name: true, plan: true, subscriptionStatus: true }
                },
                store: {
                    select: { id: true, name: true, waNumber: true, location: true }
                }
            }
        });
        if (!user) return errorResponse(res, "User not found", 404);
        successResponse(res, user);
    } catch (error) {
        errorResponse(res, "Failed to fetch profile", 500);
    }
};

module.exports = { register, login, getProfile, updateStoreProfile };
