/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{js,jsx}'],
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        emergency: {
          DEFAULT: '#E53935',
          dark: '#B71C1C',
          light: '#FFCDD2',
        },
      },
    },
  },
  plugins: [],
};
