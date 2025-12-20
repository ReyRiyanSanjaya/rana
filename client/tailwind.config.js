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
                primary: '#4F46E5', // Indigo 600
                secondary: '#0F172A', // Slate 900
                success: '#10B981',
                warning: '#F59E0B',
                danger: '#EF4444',
            }
        },
    },
    plugins: [],
}
