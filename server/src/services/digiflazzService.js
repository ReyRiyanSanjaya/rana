const crypto = require('crypto');
const https = require('https');
const { URL } = require('url');
const { PrismaClient } = require('@prisma/client');

const md5 = (value) => crypto.createHash('md5').update(value).digest('hex');

let prisma;
const getPrisma = () => {
  if (!prisma) prisma = new PrismaClient();
  return prisma;
};

const deriveAesKey = (secret) =>
  crypto.createHash('sha256').update(String(secret || '')).digest();

const decryptIfNeeded = (value) => {
  const raw = (value || '').toString();
  if (!raw) return '';
  if (!raw.startsWith('enc:v1:')) return raw;

  try {
    const secret =
      process.env.SETTINGS_ENCRYPTION_KEY ||
      process.env.JWT_SECRET ||
      'super_secret_key_change_in_prod';
    const key = deriveAesKey(secret);

    const packed = Buffer.from(raw.slice('enc:v1:'.length), 'base64');
    if (packed.length < 12 + 16) return '';

    const iv = packed.subarray(0, 12);
    const tag = packed.subarray(12, 28);
    const ciphertext = packed.subarray(28);

    const decipher = crypto.createDecipheriv('aes-256-gcm', key, iv);
    decipher.setAuthTag(tag);
    const plaintext = Buffer.concat([decipher.update(ciphertext), decipher.final()]);
    return plaintext.toString('utf8');
  } catch {
    return '';
  }
};

const postJson = (urlString, payload, { timeoutMs = 30000 } = {}) =>
  new Promise((resolve, reject) => {
    const url = new URL(urlString);
    const body = JSON.stringify(payload ?? {});

    const req = https.request(
      {
        method: 'POST',
        hostname: url.hostname,
        port: url.port || 443,
        path: `${url.pathname}${url.search}`,
        headers: {
          'Content-Type': 'application/json',
          'Content-Length': Buffer.byteLength(body),
        },
        timeout: timeoutMs,
      },
      (res) => {
        let data = '';
        res.setEncoding('utf8');
        res.on('data', (chunk) => {
          data += chunk;
        });
        res.on('end', () => {
          try {
            const parsed = data ? JSON.parse(data) : {};
            if (res.statusCode && res.statusCode >= 200 && res.statusCode < 300) {
              resolve(parsed);
              return;
            }
            const err = new Error(parsed?.data?.message || parsed?.message || `HTTP ${res.statusCode}`);
            err.statusCode = res.statusCode;
            err.response = parsed;
            reject(err);
          } catch (e) {
            const err = new Error(`Invalid JSON response (HTTP ${res.statusCode})`);
            err.statusCode = res.statusCode;
            err.raw = data;
            reject(err);
          }
        });
      }
    );

    req.on('timeout', () => {
      req.destroy(new Error('Request timeout'));
    });
    req.on('error', reject);
    req.write(body);
    req.end();
  });

let cachedCfg = null;
let cachedCfgUntil = 0;

const loadSystemSettingsMap = async () => {
  try {
    const rows = await getPrisma().systemSettings.findMany();
    const map = {};
    for (const r of rows) map[r.key] = r.value;
    return map;
  } catch {
    return {};
  }
};

const getConfig = async () => {
  const now = Date.now();
  if (cachedCfg && now < cachedCfgUntil) return cachedCfg;

  const db = await loadSystemSettingsMap();

  const username = db.DIGIFLAZZ_USERNAME || process.env.DIGIFLAZZ_USERNAME;
  const apiKeyRaw = db.DIGIFLAZZ_API_KEY || process.env.DIGIFLAZZ_API_KEY;
  const apiKey = decryptIfNeeded(apiKeyRaw);
  const baseUrl =
    db.DIGIFLAZZ_BASE_URL ||
    process.env.DIGIFLAZZ_BASE_URL ||
    'https://api.digiflazz.com/v1';
  const mode = (db.DIGIFLAZZ_MODE || process.env.DIGIFLAZZ_MODE || 'production')
    .toLowerCase();

  const markupFlat = Number(db.DIGIFLAZZ_MARKUP_FLAT ?? process.env.DIGIFLAZZ_MARKUP_FLAT ?? '0');
  const markupPercent = Number(
    db.DIGIFLAZZ_MARKUP_PERCENT ?? process.env.DIGIFLAZZ_MARKUP_PERCENT ?? '0'
  );

  if (!username || !apiKey) {
    const err = new Error('Digiflazz credentials not configured');
    err.code = 'DIGIFLAZZ_NOT_CONFIGURED';
    throw err;
  }

  cachedCfg = {
    username,
    apiKey,
    baseUrl,
    isTesting: mode !== 'production',
    markupFlat: Number.isFinite(markupFlat) ? markupFlat : 0,
    markupPercent: Number.isFinite(markupPercent) ? markupPercent : 0,
  };
  cachedCfgUntil = now + 30_000;
  return cachedCfg;
};

const applyMarkup = (amount, { markupFlat, markupPercent }) => {
  const base = Number(amount) || 0;
  const withPercent = base + base * ((Number(markupPercent) || 0) / 100);
  const withFlat = withPercent + (Number(markupFlat) || 0);
  return Math.max(0, Math.round(withFlat));
};

const normalizeDigiflazzStatus = (status) => {
  const s = (status || '').toString().toLowerCase();
  if (s === 'sukses' || s === 'success') return 'SUCCESS';
  if (s === 'pending' || s === 'processing') return 'PENDING';
  if (s === 'gagal' || s === 'failed') return 'FAILED';
  return 'UNKNOWN';
};

const priceList = async ({ cmd, code, category, brand, type }) => {
  const cfg = await getConfig();
  const payload = {
    cmd,
    username: cfg.username,
    sign: md5(`${cfg.username}${cfg.apiKey}pricelist`),
  };
  if (code) payload.code = code;
  if (category) payload.category = category;
  if (brand) payload.brand = brand;
  if (type) payload.type = type;

  const res = await postJson(`${cfg.baseUrl}/price-list`, payload);
  return Array.isArray(res?.data) ? res.data : [];
};

const transactionPrepaid = async ({ buyerSkuCode, customerNo, refId, maxPrice, cbUrl, allowDot }) => {
  const cfg = await getConfig();
  const payload = {
    username: cfg.username,
    buyer_sku_code: buyerSkuCode,
    customer_no: customerNo,
    ref_id: refId,
    sign: md5(`${cfg.username}${cfg.apiKey}${refId}`),
  };

  if (cfg.isTesting) payload.testing = true;
  if (maxPrice != null) payload.max_price = maxPrice;
  if (cbUrl) payload.cb_url = cbUrl;
  if (allowDot === true) payload.allow_dot = true;

  const res = await postJson(`${cfg.baseUrl}/transaction`, payload);
  return res?.data || null;
};

const transactionPostpaid = async ({ command, buyerSkuCode, customerNo, refId, amount }) => {
  const cfg = await getConfig();
  const payload = {
    commands: command,
    username: cfg.username,
    buyer_sku_code: buyerSkuCode,
    customer_no: customerNo,
    ref_id: refId,
    sign: md5(`${cfg.username}${cfg.apiKey}${refId}`),
  };

  if (amount != null) payload.amount = amount;
  if (cfg.isTesting) payload.testing = true;

  const res = await postJson(`${cfg.baseUrl}/transaction`, payload);
  return res?.data || null;
};

module.exports = {
  getConfig,
  applyMarkup,
  normalizeDigiflazzStatus,
  priceList,
  transactionPrepaid,
  transactionPostpaid,
};
