/** @type {import('tailwindcss').Config} */
export default {
    content: [
        "./index.html",
        "./src/**/*.{js,ts,jsx,tsx}",
    ],
    darkMode: 'class', // Enable class-based dark mode
    theme: {
        extend: {
            colors: {
                primary: '#BF092F', // Red Brand
                secondary: '#0F172A', // Slate 900
                success: '#10B981',
                warning: '#F59E0B',
                danger: '#EF4444',
            }
        },
    },
    plugins: [],
}
