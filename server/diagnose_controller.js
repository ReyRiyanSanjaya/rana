try {
    const controller = require('./src/controllers/adminController');
    console.log("✅ Controller Loaded Successfully");
    console.log("Exports:", Object.keys(controller));

    if (typeof controller.getDashboardStats === 'function') {
        console.log("✅ getDashboardStats is a function");
    } else {
        console.error("❌ getDashboardStats is MISSING or not a function");
    }

} catch (e) {
    console.error("❌ Failed to load controller:", e.message);
}
