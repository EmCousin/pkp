const defaultTheme = require('tailwindcss/defaultTheme')

module.exports = {
  content: [
    './app/views/**/*.erb',
    './app/helpers/**/*.rb',
    './app/javascript/**/*.js',
    './app/components/**/*.{erb,html,rb}'
  ],
  theme: {
    extend: {
      keyframes: {
        'slide-in-up-out-down': {
          '0%': {
            transform: 'translateY(100%)',
            opacity: '0'
          },
          '5%': {
            transform: 'translateY(0)',
            opacity: '1'
          },
          '95%': {
            transform: 'translateY(0)',
            opacity: '1'
          },
          '100%': {
            transform: 'translateY(100%)',
            opacity: '0'
          }
        }
      },
      animation: {
        'slide-in-up-out-down': 'slide-in-up-out-down 5s ease-in-out forwards'
      }
    },
  },
  plugins: [],
}
