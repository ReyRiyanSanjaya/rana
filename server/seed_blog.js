const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

const posts = [
    {
        title: "Revolutionizing Retail: Why Modern POS Systems Are a Game Changer",
        slug: "revolutionizing-retail-modern-pos",
        summary: "Discover how upgrading to a cloud-based POS system like Rana can streamline operations, boost sales, and improve customer satisfaction.",
        content: `
      <h2>The Shift to Digital Point of Sale</h2>
      <p>Gone are the days of clunky cash registers and manual ledger books. In today's fast-paced retail environment, efficiency is king. Modern Point of Sale (POS) systems have evolved from simple calculators into powerful hubs that manage the entire business ecosystem.</p>
      
      <h3>Real-Time Inventory Management</h3>
      <p>One of the biggest pain points for retailers is inventory tracking. With Rana POS, stock levels are updated instantly with every sale. This prevents "out of stock" embarrassments and helps in forecasting demand accurately.</p>

      <h3>Data-Driven Decisions</h3>
      <p>Data is the new oil. Modern POS systems provide actionable insights—identifying best-selling products, peak hours, and customer preferences. This allows business owners to make informed decisions rather than relying on gut feeling.</p>

      <blockquote>"Rana POS didn't just digitize our sales; it gave us clarity on our entire business model." - Early Adopter</blockquote>

      <h2>Conclusion</h2>
      <p>Investing in a robust POS system is investing in the future of your business. It frees up time, reduces errors, and ultimately drives growth.</p>
    `,
        imageUrl: "https://images.unsplash.com/photo-1556742049-0cfed4f7a07d?auto=format&fit=crop&w=800&q=80",
        author: "Rana Tech Team",
        tags: ["Technology", "Retail", "Growth"],
        status: "PUBLISHED",
        publishedAt: new Date()
    },
    {
        title: "5 Strategies to Boost Customer Loyalty in 2025",
        slug: "5-strategies-customer-loyalty-2025",
        summary: "Loyalty is hard to earn and easy to lose. Here are 5 proven strategies to keep your customers coming back for more.",
        content: `
      <p>Customer acquisition is expensive. Retention is where the profit lies. Here is how you can build a loyal tribe around your brand.</p>
      
      <h3>1. Personalization at Scale</h3>
      <p>Use your POS data to understand what your customers like. A simple "Happy Birthday" discount or a recommendation based on past purchases makes customers feel valued.</p>

      <h3>2. Seamless Omnichannel Experience</h3>
      <p>Customers might see a product on Instagram and want to buy it in-store. specialized O2O (Online-to-Offline) features in Rana POS bridge this gap seamlessly.</p>

      <h3>3. Transparent Communication</h3>
      <p>Be open about your values. Modern consumers support brands that align with their beliefs. Use our "Company Profile" features to share your mission.</p>
      
      <h3>4. Speed of Service</h3>
      <p>Nobody likes to wait. Our "Flash Efficiency" core value ensures that the checkout process is frictionless.</p>

      <h3>5. Reward Programs</h3>
      <p>Implement a simple points system. It doesn't have to be complex to be effective.</p>
    `,
        imageUrl: "https://images.unsplash.com/photo-1556740738-b6a63e27c4df?auto=format&fit=crop&w=800&q=80",
        author: "Sarah Jenkins",
        tags: ["Marketing", "Tips", "Customer Success"],
        status: "PUBLISHED",
        publishedAt: new Date()
    },
    {
        title: "Mastering Cash Flow: A Guide for MSMEs",
        slug: "mastering-cash-flow-msme",
        summary: "Cash flow is the lifeline of any small business. Learn how to track every rupiah coming in and going out with Rana POS.",
        content: `
      <p>Many profitable businesses fail because they run out of cash. Understanding the difference between profit and cash flow is critical.</p>

      <h3>The Cash Gap</h3>
      <p>This is the time between when you pay for inventory and when you get paid by customers. Managing this gap is essential. Rana's financial reports give you a real-time view of your cash position.</p>

      <h3>Automated Expense Tracking</h3>
      <p>Don't let small expenses slip through the cracks. Log every petty cash transaction in the system. Over time, these small leaks can sink a ship.</p>

      <h3>Forecasting</h3>
      <p>Use historical sales data to predict future revenue. This helps in planning big purchases or expansions without jeopardizing liquidity.</p>
    `,
        imageUrl: "https://images.unsplash.com/photo-1554224155-8d04cb21cd6c?auto=format&fit=crop&w=800&q=80",
        author: "Finance Expert",
        tags: ["Finance", "MSME", "Guide"],
        status: "PUBLISHED",
        publishedAt: new Date()
    }
];

async function main() {
    console.log('Start seeding blog posts...');
    for (const post of posts) {
        const exists = await prisma.blogPost.findUnique({ where: { slug: post.slug } });
        if (!exists) {
            await prisma.blogPost.create({ data: post });
            console.log(`Created post: ${post.title}`);
        } else {
            console.log(`Skipped existing: ${post.title}`);
        }
    }
    console.log('Seeding finished.');
}

main()
    .catch((e) => {
        console.error(e);
        process.exit(1);
    })
    .finally(async () => {
        await prisma.$disconnect();
    });
