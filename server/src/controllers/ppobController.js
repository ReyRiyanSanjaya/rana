const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
const { successResponse, errorResponse } = require('../utils/response');
const crypto = require('crypto');
const {
    getConfig,
    applyMarkup,
    normalizeDigiflazzStatus,
    priceList,
    transactionPrepaid,
    transactionPostpaid
} = require('../services/digiflazzService');

const resolveStoreId = async ({ storeId, tenantId }) => {
    if (storeId) return storeId;
    if (!tenantId) return null;
    const s = await prisma.store.findFirst({ where: { tenantId } });
    return s?.id || null;
};

const newRefId = (storeId) => {
    const suffix = crypto.randomBytes(6).toString('hex');
    return `ppob_${storeId}_${Date.now()}_${suffix}`;
};

const toNumberOrNull = (value) => {
    if (value === null || value === undefined) return null;
    const n = Number(value);
    return Number.isFinite(n) ? n : null;
};

const purchaseProduct = async (req, res) => {
    try {
        const cfg = await getConfig();
        const { tenantId } = req.user;
        let { storeId } = req.user;
        storeId = await resolveStoreId({ storeId, tenantId });
        if (!storeId) return errorResponse(res, "Store not found", 404);

        const { productId, customerId, commands, refId: requestRefId, amount } = req.body;
        const requestedBuyerSkuCode = (productId || '').toString();
        const requestedCustomerNo = (customerId || '').toString();
        const command = commands ? commands.toString() : null;

        if (!requestedCustomerNo) return errorResponse(res, "Invalid customerId", 400);

        const isPostpaidPay = command === 'pay-pasca';
        if (isPostpaidPay && !requestRefId) return errorResponse(res, "Invalid refId", 400);

        const refId = (requestRefId ? requestRefId.toString() : newRefId(storeId)).toString();

        let ppobTxn = await prisma.ppobTransaction.findUnique({ where: { refId } });
        if (ppobTxn && ppobTxn.tenantId !== tenantId) return errorResponse(res, "Not found", 404);
        if (ppobTxn && ppobTxn.status === 'SUCCESS') {
            return successResponse(res, {
                refId: ppobTxn.refId,
                status: ppobTxn.status,
                message: ppobTxn.message,
                rc: ppobTxn.rc,
                sn: ppobTxn.sn,
                price: ppobTxn.providerPrice,
                sellingPrice: ppobTxn.providerSellingPrice,
                chargeAmount: ppobTxn.chargeAmount
            });
        }
        if (ppobTxn && ppobTxn.status === 'FAILED') {
            return errorResponse(res, "Transaksi sudah gagal, buat transaksi baru", 400);
        }

        let buyerSkuCode = requestedBuyerSkuCode;
        let customerNo = requestedCustomerNo;
        let chargeAmount = ppobTxn?.chargeAmount ?? null;

        if (isPostpaidPay) {
            if (!ppobTxn) {
                return errorResponse(res, "Inquiry tidak ditemukan", 404);
            }
            if (ppobTxn.storeId !== storeId) return errorResponse(res, "Not found", 404);
            if (ppobTxn.command !== 'inq-pasca' && ppobTxn.command !== 'pay-pasca') {
                return errorResponse(res, "Transaksi tidak valid", 400);
            }
            buyerSkuCode = buyerSkuCode || ppobTxn.buyerSkuCode;
            customerNo = customerNo || ppobTxn.customerNo;
            if (buyerSkuCode !== ppobTxn.buyerSkuCode || customerNo !== ppobTxn.customerNo) {
                return errorResponse(res, "Data transaksi tidak sesuai", 400);
            }

            if (chargeAmount == null) {
                const base = (ppobTxn.providerSellingPrice ?? ppobTxn.providerPrice);
                if (base != null && base > 0) chargeAmount = applyMarkup(base, cfg);
            }
            if (chargeAmount == null || chargeAmount <= 0) {
                return errorResponse(res, "Tagihan belum valid, lakukan inquiry ulang", 400);
            }
        } else {
            if (!buyerSkuCode) return errorResponse(res, "Invalid productId", 400);
            if (chargeAmount == null) {
                const dp = await prisma.digitalProduct.findUnique({ where: { sku: buyerSkuCode } });
                const dpSelling = toNumberOrNull(dp?.sellingPrice);
                const dpBase = toNumberOrNull(dp?.price);
                if (dpSelling != null && dpSelling > 0) chargeAmount = dpSelling;
                else if (dpBase != null && dpBase > 0) chargeAmount = applyMarkup(dpBase, cfg);
            }
            if (chargeAmount == null || chargeAmount <= 0) {
                return errorResponse(res, "Produk belum tersedia, silakan refresh daftar produk", 400);
            }
        }

        let walletLogId = ppobTxn?.walletLogId ?? null;
        if (!walletLogId) {
            try {
                const walletResult = await prisma.$transaction(async (tx) => {
                    const store = await tx.store.findUnique({ where: { id: storeId } });
                    if (!store) throw new Error("Store not found");
                    if (store.balance < chargeAmount) throw new Error("Saldo tidak mencukupi");

                    await tx.store.update({
                        where: { id: storeId },
                        data: { balance: { decrement: chargeAmount } }
                    });

                    const log = await tx.cashflowLog.create({
                        data: {
                            tenantId,
                            storeId,
                            amount: chargeAmount,
                            type: 'CASH_OUT',
                            category: 'OTHER',
                            description: `PPOB ${buyerSkuCode} ke ${customerNo} (refId ${refId})`,
                            occurredAt: new Date()
                        }
                    });

                    return { logId: log.id };
                });
                walletLogId = walletResult.logId;
            } catch (e) {
                if (e.message === "Saldo tidak mencukupi") {
                    return errorResponse(res, "Saldo tidak mencukupi", 402);
                }
                throw e;
            }
        }

        if (!ppobTxn) {
            ppobTxn = await prisma.ppobTransaction.create({
                data: {
                    tenantId,
                    storeId,
                    refId,
                    buyerSkuCode,
                    customerNo,
                    command: isPostpaidPay ? 'pay-pasca' : 'prepaid',
                    status: 'PROCESSING',
                    chargeAmount,
                    walletLogId
                }
            });
        } else {
            ppobTxn = await prisma.ppobTransaction.update({
                where: { id: ppobTxn.id },
                data: {
                    command: isPostpaidPay ? 'pay-pasca' : ppobTxn.command,
                    status: 'PROCESSING',
                    chargeAmount,
                    walletLogId
                }
            });
        }

        let providerData = null;
        try {
            providerData = isPostpaidPay
                ? await transactionPostpaid({ command: 'pay-pasca', buyerSkuCode, customerNo, refId, amount })
                : await transactionPrepaid({ buyerSkuCode, customerNo, refId });
        } catch (e) {
            await prisma.ppobTransaction.update({
                where: { id: ppobTxn.id },
                data: {
                    status: 'PENDING',
                    message: e.message || 'Provider error',
                }
            });
            return successResponse(res, { refId, status: 'PENDING' });
        }

        const providerStatus = normalizeDigiflazzStatus(providerData?.status);
        const providerPrice = toNumberOrNull(providerData?.price);
        const providerSellingPrice = toNumberOrNull(providerData?.selling_price);
        const finalStatus = providerStatus === 'UNKNOWN' ? 'PENDING' : providerStatus;

        await prisma.ppobTransaction.update({
            where: { id: ppobTxn.id },
            data: {
                status: finalStatus,
                message: providerData?.message || null,
                rc: providerData?.rc?.toString() || null,
                sn: providerData?.sn?.toString() || null,
                providerPrice: providerPrice,
                providerSellingPrice: providerSellingPrice,
                rawResponse: providerData || undefined
            }
        });

        if (finalStatus === 'FAILED' && walletLogId && chargeAmount) {
            await prisma.$transaction(async (tx) => {
                await tx.store.update({
                    where: { id: storeId },
                    data: { balance: { increment: chargeAmount } }
                });

                await tx.cashflowLog.create({
                    data: {
                        tenantId,
                        storeId,
                        amount: chargeAmount,
                        type: 'CASH_IN',
                        category: 'OTHER',
                        description: `Refund PPOB (refId ${refId})`,
                        occurredAt: new Date()
                    }
                });
            });
        }

        return successResponse(res, {
            refId,
            status: finalStatus,
            message: providerData?.message || null,
            rc: providerData?.rc?.toString() || null,
            sn: providerData?.sn?.toString() || null,
            price: providerPrice,
            sellingPrice: providerSellingPrice,
            chargeAmount
        });

    } catch (error) {
        if (error.code === 'DIGIFLAZZ_NOT_CONFIGURED') {
            return errorResponse(res, "PPOB belum dikonfigurasi", 503);
        }
        console.error(error);
        return errorResponse(res, "Transaksi Gagal", 500);
    }
};

const getProducts = async (req, res) => {
    try {
        const cfg = await getConfig();
        const { cmd, category, brand, type, code, service } = req.query;
        let listCmd = cmd === 'pasca' ? 'pasca' : 'prepaid';
        let resolvedCategory = category;
        let resolvedBrand = brand;
        let resolvedType = type;

        if (service) {
            const s = service.toString().toLowerCase();
            if (s.includes('pulsa')) {
                listCmd = 'prepaid';
                resolvedCategory = 'Pulsa';
            } else if (s.includes('paket') || s.includes('data')) {
                listCmd = 'prepaid';
                resolvedCategory = 'Data';
            } else if (s.includes('voucher') || s.includes('game')) {
                listCmd = 'prepaid';
                resolvedCategory = 'Games';
            } else if (s.includes('e-wallet') || s.includes('ewallet') || s.includes('e money') || s.includes('emoney')) {
                listCmd = 'prepaid';
                resolvedCategory = 'E-Money';
            } else if (s.includes('pln') || s.includes('listrik') || s.includes('token')) {
                listCmd = 'prepaid';
                resolvedCategory = 'PLN';
            } else if (s.includes('bpjs')) {
                listCmd = 'pasca';
                resolvedBrand = 'BPJS';
            } else if (s.includes('pdam') || s.includes('air')) {
                listCmd = 'pasca';
                resolvedBrand = 'PDAM';
            } else if (s.includes('tv')) {
                listCmd = 'pasca';
                resolvedBrand = 'TV';
            }
        }

        const products = await priceList({
            cmd: listCmd,
            category: resolvedCategory || undefined,
            brand: resolvedBrand || undefined,
            type: resolvedType || undefined,
            code: code || undefined
        });

        if (listCmd === 'prepaid') {
            const normalized = products
                .filter((p) => p?.buyer_product_status === true && p?.seller_product_status === true)
                .map((p) => {
                    const base = Number(p.price) || 0;
                    const selling = applyMarkup(base, cfg);
                    return {
                        id: p.buyer_sku_code,
                        name: p.product_name,
                        category: (p.category || '').toString(),
                        brand: (p.brand || '').toString(),
                        type: (p.type || '').toString(),
                        price: selling,
                        providerPrice: base,
                        desc: p.desc || null
                    };
                })
                .sort((a, b) => a.price - b.price);

            for (const p of normalized) {
                await prisma.digitalProduct.upsert({
                    where: { sku: p.id },
                    update: {
                        name: p.name,
                        category: p.category.toLowerCase(),
                        brand: p.brand,
                        price: p.providerPrice,
                        sellingPrice: p.price,
                        isActive: true
                    },
                    create: {
                        sku: p.id,
                        name: p.name,
                        category: p.category.toLowerCase(),
                        brand: p.brand,
                        price: p.providerPrice,
                        sellingPrice: p.price,
                        isActive: true
                    }
                });
            }

            return successResponse(res, normalized);
        }

        const normalizedPasca = products
            .filter((p) => p?.buyer_product_status === true && p?.seller_product_status === true)
            .map((p) => ({
                id: p.buyer_sku_code,
                name: p.product_name,
                category: (p.category || '').toString(),
                brand: (p.brand || '').toString(),
                admin: Number(p.admin) || 0,
                isPostpaid: true,
                desc: p.desc || null
            }))
            .sort((a, b) => a.name.localeCompare(b.name));

        return successResponse(res, normalizedPasca);
    } catch (error) {
        if (error.code === 'DIGIFLAZZ_NOT_CONFIGURED') {
            return errorResponse(res, "PPOB belum dikonfigurasi", 503);
        }
        console.error(error);
        return errorResponse(res, "Failed to fetch PPOB products", 500);
    }
};

const checkBill = async (req, res) => {
    try {
        const cfg = await getConfig();
        const { tenantId } = req.user;
        let { storeId } = req.user;
        storeId = await resolveStoreId({ storeId, tenantId });
        if (!storeId) return errorResponse(res, "Store not found", 404);

        const { customerId, type, productId, amount } = req.body;
        const customerNo = (customerId || '').toString();
        const buyerSkuCode = (productId || '').toString();
        if (!customerNo) return errorResponse(res, "Invalid Customer ID", 400);

        const refId = newRefId(storeId);

        let resolvedSku = buyerSkuCode;
        if (!resolvedSku) {
            const t = (type || '').toString().toLowerCase();
            if (t.includes('pln') || t.includes('listrik')) resolvedSku = 'pln';
            else if (t.includes('bpjs')) resolvedSku = 'bpjs';
            else if (t.includes('pdam') || t.includes('air')) resolvedSku = 'pdam';
        }
        if (!resolvedSku) return errorResponse(res, "Invalid productId for inquiry", 400);

        const inquiry = await transactionPostpaid({
            command: 'inq-pasca',
            buyerSkuCode: resolvedSku,
            customerNo,
            refId,
            amount
        });

        const providerStatus = normalizeDigiflazzStatus(inquiry?.status);
        const providerPrice = toNumberOrNull(inquiry?.price);
        const providerSellingPrice = toNumberOrNull(inquiry?.selling_price);
        const chargeBase = providerSellingPrice ?? providerPrice;
        const estimatedCharge = chargeBase != null ? applyMarkup(chargeBase, cfg) : null;

        await prisma.ppobTransaction.create({
            data: {
                tenantId,
                storeId,
                refId,
                buyerSkuCode: resolvedSku,
                customerNo,
                command: 'inq-pasca',
                status: providerStatus === 'UNKNOWN' ? 'PENDING' : providerStatus,
                message: inquiry?.message || null,
                rc: inquiry?.rc?.toString() || null,
                providerPrice,
                providerSellingPrice,
                chargeAmount: estimatedCharge,
                rawResponse: inquiry || undefined
            }
        });

        return successResponse(res, {
            refId,
            buyerSkuCode: resolvedSku,
            customerNo,
            status: providerStatus,
            message: inquiry?.message || null,
            rc: inquiry?.rc?.toString() || null,
            customerName: inquiry?.customer_name || null,
            admin: toNumberOrNull(inquiry?.admin),
            price: providerPrice,
            sellingPrice: providerSellingPrice,
            estimatedCharge,
            desc: inquiry?.desc || null,
            periode: inquiry?.periode || null
        });
    } catch (error) {
        if (error.code === 'DIGIFLAZZ_NOT_CONFIGURED') {
            return errorResponse(res, "PPOB belum dikonfigurasi", 503);
        }
        return errorResponse(res, "Inquiry Failed", 500);
    }
};

const checkStatus = async (req, res) => {
    try {
        await getConfig();
        const { tenantId } = req.user;
        const { refId } = req.params;
        if (!refId) return errorResponse(res, "Invalid refId", 400);

        const tx = await prisma.ppobTransaction.findUnique({ where: { refId } });
        if (!tx || tx.tenantId !== tenantId) return errorResponse(res, "Not found", 404);

        let providerData = null;
        if (tx.command === 'inq-pasca' || tx.command === 'pay-pasca') {
            providerData = await transactionPostpaid({
                command: 'status-pasca',
                buyerSkuCode: tx.buyerSkuCode,
                customerNo: tx.customerNo,
                refId: tx.refId
            });
        } else {
            providerData = await transactionPrepaid({
                buyerSkuCode: tx.buyerSkuCode,
                customerNo: tx.customerNo,
                refId: tx.refId
            });
        }

        const providerStatus = normalizeDigiflazzStatus(providerData?.status);
        const newStatus = providerStatus === 'UNKNOWN' ? tx.status : providerStatus;

        await prisma.ppobTransaction.update({
            where: { id: tx.id },
            data: {
                status: newStatus,
                message: providerData?.message || tx.message,
                rc: providerData?.rc?.toString() || tx.rc,
                sn: providerData?.sn?.toString() || tx.sn,
                rawResponse: providerData || undefined
            }
        });

        if (tx.status === 'PENDING' && newStatus === 'FAILED' && tx.chargeAmount) {
            await prisma.$transaction(async (p) => {
                await p.store.update({
                    where: { id: tx.storeId },
                    data: { balance: { increment: tx.chargeAmount } }
                });
                await p.cashflowLog.create({
                    data: {
                        tenantId: tx.tenantId,
                        storeId: tx.storeId,
                        amount: tx.chargeAmount,
                        type: 'CASH_IN',
                        category: 'OTHER',
                        description: `Refund PPOB (refId ${tx.refId})`,
                        occurredAt: new Date()
                    }
                });
            });
        }

        return successResponse(res, {
            refId: tx.refId,
            status: newStatus,
            message: providerData?.message || tx.message,
            rc: providerData?.rc?.toString() || tx.rc,
            sn: providerData?.sn?.toString() || tx.sn
        });
    } catch (error) {
        if (error.code === 'DIGIFLAZZ_NOT_CONFIGURED') {
            return errorResponse(res, "PPOB belum dikonfigurasi", 503);
        }
        console.error(error);
        return errorResponse(res, "Cek status gagal", 500);
    }
};

const digiflazzWebhook = async (req, res) => {
    try {
        const secret = process.env.DIGIFLAZZ_WEBHOOK_SECRET;
        if (secret) {
            const header = (req.headers['x-digiflazz-secret'] || '').toString();
            if (header !== secret) return res.status(401).json({ status: 'unauthorized' });
        }

        const data = req.body?.data || req.body;
        const refId = data?.ref_id?.toString();
        if (!refId) return res.status(400).json({ status: 'invalid' });

        const tx = await prisma.ppobTransaction.findUnique({ where: { refId } });
        if (!tx) return res.json({ status: 'ok' });

        const providerStatus = normalizeDigiflazzStatus(data?.status);
        const newStatus = providerStatus === 'UNKNOWN' ? tx.status : providerStatus;

        await prisma.ppobTransaction.update({
            where: { id: tx.id },
            data: {
                status: newStatus,
                message: data?.message?.toString() || tx.message,
                rc: data?.rc?.toString() || tx.rc,
                sn: data?.sn?.toString() || tx.sn,
                rawResponse: data || undefined
            }
        });

        if (tx.status === 'PENDING' && newStatus === 'FAILED' && tx.chargeAmount) {
            await prisma.$transaction(async (p) => {
                await p.store.update({
                    where: { id: tx.storeId },
                    data: { balance: { increment: tx.chargeAmount } }
                });
                await p.cashflowLog.create({
                    data: {
                        tenantId: tx.tenantId,
                        storeId: tx.storeId,
                        amount: tx.chargeAmount,
                        type: 'CASH_IN',
                        category: 'OTHER',
                        description: `Refund PPOB (refId ${tx.refId})`,
                        occurredAt: new Date()
                    }
                });
            });
        }

        return res.json({ status: 'ok' });
    } catch (e) {
        console.error(e);
        return res.status(500).json({ status: 'error' });
    }
};

module.exports = { getProducts, checkBill, purchaseProduct, checkStatus, digiflazzWebhook };
