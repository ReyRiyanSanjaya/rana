async function testApi() {
    const baseUrl = 'http://localhost:4000/api';
    console.log(`Target: ${baseUrl}`);

    try {
        // 1. Login
        console.log("1. Logging in...");
        const loginRes = await fetch(`${baseUrl}/auth/login`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ email: 'super@rana.com', password: 'password123' })
        });

        if (!loginRes.ok) throw new Error(`Login Failed: ${loginRes.status} ${loginRes.statusText}`);
        const loginData = await loginRes.json();
        const token = loginData.data?.token;

        if (!token) throw new Error("No token received");
        console.log("✅ Login Successful! Token received.");

        // 2. Fetch Stats
        console.log("\n2. Fetching Dashboard Stats...");
        const statsRes = await fetch(`${baseUrl}/admin/stats`, {
            headers: { 'Authorization': `Bearer ${token}` }
        });

        if (!statsRes.ok) throw new Error(`Stats Failed: ${statsRes.status} ${statsRes.statusText}`);
        const statsData = await statsRes.json();
        console.log("✅ Stats Received:", JSON.stringify(statsData.data, null, 2));

        // 3. Fetch Chart
        console.log("\n3. Fetching Chart...");
        const chartRes = await fetch(`${baseUrl}/admin/stats/chart`, {
            headers: { 'Authorization': `Bearer ${token}` }
        });

        if (!chartRes.ok) throw new Error(`Chart Failed: ${chartRes.status} ${chartRes.statusText}`);
        console.log("✅ Chart Data Received");

    } catch (error) {
        console.error("❌ API Test Failed:", error.message);
        if (error.cause) console.error(error.cause);
    }
}

testApi();
