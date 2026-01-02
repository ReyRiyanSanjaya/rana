const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const { successResponse, errorResponse } = require('../utils/response');
const https = require('https');
const fs = require('fs');
const path = require('path');

const SECRET_KEY = process.env.JWT_SECRET || 'super_secret_key_change_in_prod';

const normalizeEmail = (value) => (value || '').toString().trim().toLowerCase();

const normalizePhone = (value) => {
    let digits = (value || '').toString().replace(/[^\d]/g, '');
    if (!digits) return '';
    if (digits.startsWith('0')) digits = `62${digits.slice(1)}`;
    if (digits.startsWith('8')) digits = `62${digits}`;
    if (digits.startsWith('620')) digits = `62${digits.slice(3)}`;
    return digits;
};

const isLikelyPhoneNumber = (value) => {
    const digits = normalizePhone(value);
    if (!digits) return false;
    if (!digits.startsWith('62')) return false;
    if (digits.length < 10 || digits.length > 15) return false;
    return true;
};

const buildPhoneCandidates = (rawValue) => {
    const raw = (rawValue || '').toString().trim();
    const normalized = normalizePhone(raw);
    const candidates = new Set();
    if (raw) candidates.add(raw);
    if (normalized) {
        candidates.add(normalized);
        candidates.add(`+${normalized}`);
        if (normalized.startsWith('62')) candidates.add(`0${normalized.slice(2)}`);
    }
    return Array.from(candidates);
};

const getUrlText = (url, { timeoutMs = 5000, maxBytes = 64 * 1024, redirectsLeft = 5 } = {}) => {
    return new Promise((resolve, reject) => {
        const req = https.get(
            url,
            { headers: { 'user-agent': 'RanaPOS/1.0' } },
            (res) => {
                const statusCode = res.statusCode || 0;
                const location = res.headers.location;
                if ([301, 302, 303, 307, 308].includes(statusCode) && location && redirectsLeft > 0) {
                    res.resume();
                    const nextUrl = new URL(location, url).toString();
                    getUrlText(nextUrl, { timeoutMs, maxBytes, redirectsLeft: redirectsLeft - 1 })
                        .then(resolve)
                        .catch(reject);
                    return;
                }

                let size = 0;
                const chunks = [];

                res.on('data', (chunk) => {
                    size += chunk.length;
                    if (size > maxBytes) {
                        req.destroy(new Error('Response too large'));
                        return;
                    }
                    chunks.push(chunk);
                });

                res.on('end', () => {
                    resolve({
                        statusCode,
                        body: Buffer.concat(chunks).toString('utf8'),
                        finalUrl: url
                    });
                });
            }
        );

        req.on('error', reject);
        req.setTimeout(timeoutMs, () => req.destroy(new Error('Request timeout')));
    });
};

const verifyWhatsAppNumberWithoutOtp = async (value) => {
    const digits = normalizePhone(value);
    if (!digits) return false;
    try {
        const { statusCode, body } = await getUrlText(`https://wa.me/${digits}`, { timeoutMs: 5000 });
        if (!statusCode || statusCode >= 400) return false;
        const text = (body || '').toLowerCase();
        const invalidMarkers = [
            'phone number shared via url is invalid',
            'shared via url is invalid',
            'invalid phone number',
            'nomor telepon yang dibagikan'
        ];
        if (invalidMarkers.some((m) => text.includes(m))) return false;
        return true;
    } catch (_) {
        return false;
    }
};

const isStrongPassword = (value) => {
    const password = (value || '').toString();
    if (password.length < 8) return false;
    const hasLetter = /[A-Za-z]/.test(password);
    const hasNumber = /\d/.test(password);
    return hasLetter && hasNumber;
};

const saveStoreImage = (base64String, tenantId, storeId) => {
    try {
        if (!base64String) return null;

        const matches = base64String.match(/^data:([A-Za-z-+\/]+);base64,(.+)$/);
        if (!matches || matches.length !== 3) return null;

        const mimeType = matches[1];
        if (!mimeType.startsWith('image/')) return null;

        const buffer = Buffer.from(matches[2], 'base64');
        const ext = mimeType.split('/')[1] || 'jpg';
        const safeExt = ext.replace(/[^a-z0-9]/gi, '').toLowerCase() || 'jpg';
        const fileName = `store_${storeId}_${Date.now()}.${safeExt}`;

        const uploadDir = path.join(__dirname, '../../uploads/stores', tenantId);
        if (!fs.existsSync(uploadDir)) fs.mkdirSync(uploadDir, { recursive: true });

        fs.writeFileSync(path.join(uploadDir, fileName), buffer);
        return `/uploads/stores/${tenantId}/${fileName}`;
    } catch (_) {
        return null;
    }
};

// REGISTER (Onboarding Tenant)
const register = async (req, res) => {
    try {
        const {
            businessName,
            ownerName,
            email,
            password,
            role,
            waNumber,
            latitude,
            longitude,
            address,
            category,
            storeImageBase64,
            name,
            phone,
            referralCode
        } = req.body;

        const normalizedEmail = normalizeEmail(email);
        const normalizedRole = (role || '').toString().trim().toUpperCase();

        if (!normalizedEmail || !password) return errorResponse(res, "Missing required fields", 400);
        if (!isStrongPassword(password)) return errorResponse(res, "Password too weak", 400);

        // 1. Check if user exists
        const existingUser = await prisma.user.findUnique({ where: { email: normalizedEmail } });
        if (existingUser) return errorResponse(res, "Email sudah digunakan", 400);

        // 2. Hash Password
        const hashedPassword = await bcrypt.hash(password, 10);

        if (normalizedRole === 'BUYER') {
            const buyerName = (name || '').toString().trim();
            const buyerPhone = (phone || '').toString().trim();
            if (!buyerName) return errorResponse(res, "Missing required fields", 400);

            const buyerTenant = await prisma.tenant.upsert({
                where: { id: 'rana_market_buyer_tenant' },
                update: {},
                create: {
                    id: 'rana_market_buyer_tenant',
                    name: 'Rana Market Buyers',
                    plan: 'FREE',
                    subscriptionStatus: 'ACTIVE'
                }
            });

            const user = await prisma.user.create({
                data: {
                    email: normalizedEmail,
                    passwordHash: hashedPassword,
                    name: buyerName,
                    role: 'CASHIER',
                    tenantId: buyerTenant.id
                }
            });

            const token = jwt.sign(
                { userId: user.id, tenantId: user.tenantId, role: user.role, storeId: null },
                SECRET_KEY,
                { expiresIn: '30d' }
            );

            return successResponse(res, {
                token,
                user: { id: user.id, name: user.name, role: user.role, tenantId: user.tenantId, storeId: null },
                phone: buyerPhone
            }, "Registration Successful");
        }

        if (!businessName) return errorResponse(res, "Missing required fields", 400);
        if (!waNumber) return errorResponse(res, "Nomor WhatsApp wajib diisi", 400);
        if (!isLikelyPhoneNumber(waNumber)) return errorResponse(res, "Nomor WhatsApp tidak valid", 400);

        const normalizedWa = normalizePhone(waNumber);
        const existingStore = await prisma.store.findFirst({
            where: { waNumber: { in: buildPhoneCandidates(normalizedWa) } }
        });
        if (existingStore) return errorResponse(res, "Nomor WhatsApp sudah digunakan", 400);

        // [DISABLED] Unreliable scraping validation
        // const isWaValid = await verifyWhatsAppNumberWithoutOtp(normalizedWa);
        // if (!isWaValid) return errorResponse(res, "Nomor WhatsApp tidak valid", 400);

        // 3. Transaction: Create Tenant + User + Default Store (with Loc)
        let normalizedReferralCode = null;
        let referralContext = null;

        if (referralCode && typeof referralCode === 'string') {
            normalizedReferralCode = referralCode.toString().trim().toUpperCase();
            if (normalizedReferralCode) {
                const codeRecord = await prisma.referralCode.findUnique({
                    where: { code: normalizedReferralCode },
                    include: { program: true }
                });

                if (!codeRecord || codeRecord.status !== 'ACTIVE') {
                    return errorResponse(res, "Kode referral tidak valid", 400);
                }

                if (!codeRecord.program || codeRecord.program.status !== 'ACTIVE') {
                    return errorResponse(res, "Program referral sudah tidak aktif", 400);
                }

                referralContext = {
                    programId: codeRecord.program.id,
                    referrerTenantId: codeRecord.tenantId
                };
            }
        }

        const result = await prisma.$transaction(async (tx) => {
            const trialEndsAt = new Date();
            trialEndsAt.setDate(trialEndsAt.getDate() + 7);

            const tenant = await tx.tenant.create({
                data: {
                    name: businessName,
                    plan: 'FREE',
                    subscriptionStatus: 'TRIAL',
                    trialEndsAt
                }
            });

            const store = await tx.store.create({
                data: {
                    tenantId: tenant.id,
                    name: businessName,
                    waNumber: normalizedWa,
                    location: address,
                    category: category,
                    latitude: latitude ? parseFloat(latitude) : null,
                    longitude: longitude ? parseFloat(longitude) : null
                }
            });

            const maybeImageUrl = saveStoreImage(storeImageBase64, tenant.id, store.id);
            if (maybeImageUrl) {
                await tx.store.update({
                    where: { id: store.id },
                    data: { imageUrl: maybeImageUrl }
                });
            }

            const user = await tx.user.create({
                data: {
                    email: normalizedEmail,
                    passwordHash: hashedPassword,
                    name: (ownerName || '').toString().trim() || businessName + ' Owner',
                    role: normalizedRole === 'ADMIN' ? 'ADMIN' : 'OWNER',
                    tenant: { connect: { id: tenant.id } },
                    store: { connect: { id: store.id } }
                }
            });

            if (referralContext) {
                const program = await tx.referralProgram.findUnique({
                    where: { id: referralContext.programId }
                });

                if (program && program.status === 'ACTIVE' && program.rewardL1 > 0) {
                    const referral = await tx.referral.create({
                        data: {
                            programId: program.id,
                            referrerTenantId: referralContext.referrerTenantId,
                            refereeTenantId: tenant.id,
                            status: 'COMPLETED'
                        }
                    });

                    await tx.referralReward.create({
                        data: {
                            referralId: referral.id,
                            programId: program.id,
                            beneficiaryTenantId: referralContext.referrerTenantId,
                            level: 1,
                            amount: program.rewardL1,
                            currency: 'IDR',
                            status: 'RELEASED',
                            releasedAt: new Date()
                        }
                    });

                    const referrerStore = await tx.store.findFirst({
                        where: { tenantId: referralContext.referrerTenantId }
                    });

                    if (referrerStore) {
                        await tx.store.update({
                            where: { id: referrerStore.id },
                            data: { balance: { increment: program.rewardL1 } }
                        });

                        await tx.cashflowLog.create({
                            data: {
                                tenantId: referrerStore.tenantId,
                                storeId: referrerStore.id,
                                amount: program.rewardL1,
                                type: 'CASH_IN',
                                category: 'CAPITAL_IN',
                                description: 'Referral reward',
                                occurredAt: new Date()
                            }
                        });
                    }
                }
            }

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
        const { email, phone, password } = req.body;

        let user = null;
        let store = null;

        if (phone) {
            if (!isLikelyPhoneNumber(phone)) return errorResponse(res, "Invalid User", 401);
            const candidates = buildPhoneCandidates(phone);
            store = await prisma.store.findFirst({
                where: { waNumber: { in: candidates } }
            });
            if (!store) return errorResponse(res, "Invalid User", 401);

            user =
                (await prisma.user.findFirst({
                    where: { storeId: store.id, role: 'OWNER' }
                })) ||
                (await prisma.user.findFirst({
                    where: { storeId: store.id, role: 'ADMIN' }
                })) ||
                (await prisma.user.findFirst({
                    where: { storeId: store.id }
                }));
            if (!user) {
                user =
                    (await prisma.user.findFirst({
                        where: { tenantId: store.tenantId, role: 'OWNER' }
                    })) ||
                    (await prisma.user.findFirst({
                        where: { tenantId: store.tenantId, role: 'ADMIN' }
                    })) ||
                    (await prisma.user.findFirst({
                        where: { tenantId: store.tenantId }
                    }));
            }
            if (!user) return errorResponse(res, "Invalid User", 401);
        } else {
            const normalizedEmail = normalizeEmail(email);
            user = await prisma.user.findUnique({ where: { email: normalizedEmail } });
            if (!user) return errorResponse(res, "Invalid User", 401);
        }

        const validPass = await bcrypt.compare(password, user.passwordHash);
        if (!validPass) return errorResponse(res, "Invalid Password", 401);

        if (!store) {
            store = await prisma.store.findFirst({
                where: { tenantId: user.tenantId }
            });
        }

        try {
            await prisma.loginHistory.create({
                data: {
                    userId: user.id,
                    ip: req.ip,
                    userAgent: req.headers['user-agent']
                }
            });
        } catch (_) { }

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
        const { businessName, waNumber, address, latitude, longitude, storeImageBase64 } = req.body;

        if (businessName) {
            await prisma.tenant.update({
                where: { id: tenantId },
                data: { name: businessName }
            });
        }

        // Update Store Info (Assuming data for primary store)
        // Find store by tenantId
        const store = await prisma.store.findFirst({ where: { tenantId } });
        if (store) {
            if (waNumber) {
                if (!isLikelyPhoneNumber(waNumber)) return errorResponse(res, "Nomor WhatsApp tidak valid", 400);
                const normalizedWa = normalizePhone(waNumber);
                const dup = await prisma.store.findFirst({
                    where: {
                        waNumber: { in: buildPhoneCandidates(normalizedWa) },
                        NOT: { id: store.id }
                    }
                });
                if (dup) return errorResponse(res, "Nomor WhatsApp sudah digunakan", 400);
            }

            const maybeImageUrl = saveStoreImage(storeImageBase64, tenantId, store.id);
            await prisma.store.update({
                where: { id: store.id },
                data: {
                    name: businessName || undefined,
                    waNumber: waNumber ? normalizePhone(waNumber) : undefined,
                    location: address,
                    latitude: latitude ? parseFloat(latitude) : undefined,
                    longitude: longitude ? parseFloat(longitude) : undefined,
                    imageUrl: maybeImageUrl || undefined
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
