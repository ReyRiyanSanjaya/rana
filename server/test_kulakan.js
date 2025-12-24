const API_URL = 'http://localhost:4000/api/wholesale';

// Mock Data
const newProduct = {
    name: "Test Product " + Date.now(),
    categoryId: "some-uuid",
    price: 10000,
    stock: 50,
    supplierName: "Test Supplier",
    description: "Test Description"
};

async function runTest() {
    try {
        console.log("1. Fetching Categories...");
        const catsRes = await fetch(`${API_URL}/categories`);
        const catsData = await catsRes.json();

        if (catsData.data.length === 0) {
            console.log("No categories found. Creating one...");
            const createCatVal = await fetch(`${API_URL}/categories`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ name: "General" })
            });
            const catRes = await createCatVal.json();
            newProduct.categoryId = catRes.data.id;
        } else {
            newProduct.categoryId = catsData.data[0].id;
        }
        console.log("Using Category ID:", newProduct.categoryId);

        console.log("2. Creating Product...");
        const createRes = await fetch(`${API_URL}/products`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(newProduct)
        });
        const createData = await createRes.json();
        const createdProduct = createData.data;
        console.log("Product Created:", createdProduct.id);

        console.log("3. Updating Product...");
        const updateRes = await fetch(`${API_URL}/products/${createdProduct.id}`, {
            method: 'PUT',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                price: 15000,
                stock: 100
            })
        });

        console.log(`Update Response Status: ${updateRes.status} ${updateRes.statusText}`);
        if (!updateRes.ok) {
            const text = await updateRes.text();
            console.log("Update Response Body (Text):", text);
            throw new Error(`Update Failed: ${updateRes.status}`);
        }

        const updateData = await updateRes.json();
        console.log("Product Updated. New Price:", updateData.data.price);

        console.log("4. Deleting Product...");
        await fetch(`${API_URL}/products/${createdProduct.id}`, { method: 'DELETE' });
        console.log("Product Deleted.");

        console.log("SUCCESS: CRUD Flow Verified.");
    } catch (error) {
        console.error("TEST FAILED:", error);
    }
}

runTest();
