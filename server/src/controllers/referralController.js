const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
const { successResponse, errorResponse } = require('../utils/response');

const DEFAULT_PROGRAM_CODE = 'DEFAULT_MERCHANT_REFERRAL';

const ensureDefaultProgram = async () => {
  const existing = await prisma.referralProgram.findUnique({
    where: { code: DEFAULT_PROGRAM_CODE },
  });
  if (existing) return existing;
  return prisma.referralProgram.create({
    data: {
      name: 'Program Referral Merchant Default',
      code: DEFAULT_PROGRAM_CODE,
      type: 'SINGLE_LEVEL',
      status: 'ACTIVE',
      maxLevels: 2,
      rewardL1: 50000,
      rewardL2: 20000,
      rewardL3: 0,
      holdDays: 0,
    },
  });
};

const generateCodeForTenant = async (tenantId) => {
  const base = tenantId.replace(/-/g, '').toUpperCase().slice(0, 6);
  for (let i = 0; i < 5; i++) {
    const suffix = Math.floor(Math.random() * 9999)
      .toString()
      .padStart(4, '0');
    const candidate = `${base}${suffix}`;
    const exists = await prisma.referralCode.findUnique({
      where: { code: candidate },
    });
    if (!exists) return candidate;
  }
  return `${base}${Date.now().toString().slice(-4)}`;
};

const getMyReferralInfo = async (req, res) => {
  try {
    const { tenantId } = req.user;
    if (!tenantId) return errorResponse(res, 'Invalid tenant', 400);

    const program = await ensureDefaultProgram();

    let codeRecord = await prisma.referralCode.findFirst({
      where: {
        tenantId,
        programId: program.id,
        status: 'ACTIVE',
      },
    });

    if (!codeRecord) {
      const code = await generateCodeForTenant(tenantId);
      codeRecord = await prisma.referralCode.create({
        data: {
          programId: program.id,
          tenantId,
          code,
          status: 'ACTIVE',
        },
      });
    }

    const totalReferrals = await prisma.referral.count({
      where: { referrerTenantId: tenantId },
    });

    const rewardAgg = await prisma.referralReward.aggregate({
      _sum: { amount: true },
      where: {
        beneficiaryTenantId: tenantId,
        status: 'RELEASED',
      },
    });

    const holdAgg = await prisma.referralReward.aggregate({
      _sum: { amount: true },
      where: {
        beneficiaryTenantId: tenantId,
        status: { in: ['CREATED', 'HOLD', 'ELIGIBLE'] },
      },
    });

    return successResponse(res, {
      code: codeRecord.code,
      program: {
        id: program.id,
        name: program.name,
        type: program.type,
        maxLevels: program.maxLevels,
        rewardL1: program.rewardL1,
        rewardL2: program.rewardL2,
        rewardL3: program.rewardL3,
      },
      stats: {
        totalReferrals,
        totalRewardReleased: rewardAgg._sum.amount || 0,
        totalRewardPending: holdAgg._sum.amount || 0,
      },
    });
  } catch (error) {
    return errorResponse(res, 'Failed to load referral info', 500, error);
  }
};

const getMyReferrals = async (req, res) => {
  try {
    const { tenantId } = req.user;
    if (!tenantId) return errorResponse(res, 'Invalid tenant', 400);

    const referrals = await prisma.referral.findMany({
      where: { referrerTenantId: tenantId },
      orderBy: { createdAt: 'desc' },
      include: {
        referee: true,
        rewards: true,
      },
    });

    const items = referrals.map((r) => {
      const directReward = r.rewards.find((rw) => rw.level === 1) || null;
      return {
        id: r.id,
        createdAt: r.createdAt,
        status: r.status,
        referee: {
          id: r.referee.id,
          name: r.referee.name,
        },
        reward: directReward
          ? {
              amount: directReward.amount,
              currency: directReward.currency,
              status: directReward.status,
              releasedAt: directReward.releasedAt,
            }
          : null,
      };
    });

    return successResponse(res, { items });
  } catch (error) {
    return errorResponse(res, 'Failed to load referrals', 500, error);
  }
};

module.exports = { getMyReferralInfo, getMyReferrals };

