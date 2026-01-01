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
                primary: '#E07A5F', // Soft Terra Cotta
                secondary: '#334155', // Soft Slate
                success: '#10B981',
                warning: '#F59E0B',
                danger: '#EF4444',
            }
        },
    },
    plugins: [],
}
