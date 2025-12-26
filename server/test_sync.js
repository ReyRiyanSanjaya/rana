const http = require('http');

async function testSync() {
    try {
        // 1. Login to get token
        const loginPayload = JSON.stringify({
            email: 'super@rana.com',
            password: 'password123'
        });

        const loginReq = http.request({
            hostname: 'localhost',
            port: 4000,
            path: '/api/auth/login',
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Content-Length': loginPayload.length
            }
        }, (res) => {
            let data = '';
            res.on('data', (chunk) => data += chunk);
            res.on('end', () => {
                const loginRes = JSON.parse(data);
                if (!loginRes.data || !loginRes.data.token) {
                    console.error('Login Failed:', loginRes);
                    return;
                }
                const token = loginRes.data.token;
                console.log('Got Token:', token.substring(0, 10) + '...');

                // 2. Try Sync
                const syncPayload = JSON.stringify({
                    offlineId: 'TEST-OFFLINE-' + Date.now(),
                    storeId: loginRes.data.user.storeId,
                    totalAmount: 10000,
                    occurredAt: new Date().toISOString(),
                    items: [] // Invalid items to force log error or 400
                });

                const syncReq = http.request({
                    hostname: 'localhost',
                    port: 4000,
                    path: '/api/transactions/sync',
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'Content-Length': syncPayload.length,
                        'Authorization': 'Bearer ' + token
                    }
                }, (sRes) => {
                    let sData = '';
                    sRes.on('data', (c) => sData += c);
                    sRes.on('end', () => {
                        console.log('Sync Response Status:', sRes.statusCode);
                        console.log('Sync Response Body:', sData);
                    });
                });

                syncReq.on('error', (e) => console.error('Sync Req Error:', e));
                syncReq.write(syncPayload);
                syncReq.end();
            });
        });

        loginReq.on('error', (e) => console.error('Login Req Error:', e));
        loginReq.write(loginPayload);
        loginReq.end();

    } catch (e) {
        console.error(e);
    }
}

testSync();
