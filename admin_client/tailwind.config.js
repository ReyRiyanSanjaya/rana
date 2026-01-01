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
                // Soft Blue Palette for Beige Theme
                primary: {
                    50: '#F0F6FA',
                    100: '#E2EDF5',
                    200: '#C5DBEB',
                    300: '#A8C9E1',
                    400: '#8BB7D7',
                    500: '#6EA5CD',
                    600: '#669BBC', // Soft Blue Brand
                    700: '#527C96',
                    800: '#3D5D71',
                    900: '#293E4B',
                }
            }
        },
    },
    plugins: [],
}
