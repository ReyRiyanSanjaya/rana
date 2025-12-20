/** @type {import('tailwindcss').Config} */
export default {
    content: [
        "./index.html",
        "./src/**/*.{js,ts,jsx,tsx}",
    ],
    theme: {
        extend: {
            fontFamily: {
                plurk: ['"Plurit"', 'sans-serif'], // Just kidding, using Inter
                sans: ['"Inter"', 'sans-serif'],
            },
            colors: {
                // Untitled UI often uses these specific neutral tones, but slate is close enough.
                // We will stick to standard slate but maybe refine primary.
                primary: {
                    50: '#f0f9ff',
                    100: '#e0f2fe',
                    200: '#bae6fd',
                    300: '#7dd3fc',
                    400: '#38bdf8',
                    500: '#0ea5e9',
                    600: '#0284c7', // Brand default
                    700: '#0369a1',
                    800: '#075985',
                    900: '#0c4a6e',
                }
            }
        },
    },
    plugins: [],
}
