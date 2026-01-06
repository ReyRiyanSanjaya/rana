async function test() {
    try {
        console.log('Attempting login...');
        const body = JSON.stringify({
            email: 'merchant@rana.com',
            password: 'password123'
        });
        
        const controller = new AbortController();
        const timeoutId = setTimeout(() => controller.abort(), 10000); // 10s timeout

        const res = await fetch('http://localhost:4000/api/auth/login', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: body,
            signal: controller.signal
        });
        
        clearTimeout(timeoutId);

        console.log('Status:', res.status);
        const text = await res.text();
        console.log('Response:', text);
    } catch (error) {
        console.error('Error:', error.message);
        if (error.name === 'AbortError') {
            console.error('Request timed out');
        }
    }
}

test();
