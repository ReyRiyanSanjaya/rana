const http = require('http');

const options = {
    hostname: 'localhost',
    port: 4000,
    path: '/api/blog',
    method: 'GET',
    headers: {
        'Accept': 'application/json'
    }
};

const req = http.request(options, (res) => {
    console.log(`STATUS: ${res.statusCode}`);
    let data = '';
    res.on('data', (chunk) => {
        data += chunk;
    });
    res.on('end', () => {
        console.log('BODY:', data.substring(0, 200)); // Print first 200 chars
    });
});

req.on('error', (e) => {
    console.error(`problem with request: ${e.message}`);
});

req.end();
