const plugin = require('tailwindcss/plugin')

module.exports = {
  content: [
    './app/form_builders/**/*.rb',
    './app/views/**/*.erb',
    './app/helpers/**/*.rb',
    './app/javascript/**/*.js',
    './app/components/**/*.{erb,html,rb}'
  ],
  plugins: [
    plugin(function ({ matchUtilities, theme }) {
      matchUtilities(
        {
           // Class name
          'animation-duration': (value) => {
            return {
              "--animation-duration": value
            }
          },
        },
        { values: theme('transitionDuration') }
      ),
      matchUtilities(
        {
          'animation-delay': (value) => {
            return {
              animationDelay: value
            }
          }
        },
        { values: theme('transitionDelay') }
      )
    }),
  ],
  theme: {
    extend: {
      keyframes: {
        'slide-in-from-left': {
          '0%': { transform: 'translateX(200%)' },
          '100%': { transform: 'translateX(0)' }
        },
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
        },
        'fade-in-up': {
          'from': {
            opacity: '0',
            transform: 'translateY(20px)'
          },
          'to': {
            opacity: '1',
            transform: 'translateY(0)'
          }
        },
        'slide-in-from-left-custom': {
          'from': {
            opacity: '0',
            transform: 'translateX(-20px)'
          },
          'to': {
            opacity: '1',
            transform: 'translateX(0)'
          }
        },
        'scale-in': {
          'from': {
            opacity: '0',
            transform: 'scale(0.95)'
          },
          'to': {
            opacity: '1',
            transform: 'scale(1)'
          }
        },
        'pulse-glow': {
          '0%, 100%': {
            boxShadow: '0 0 0 0 rgba(59, 130, 246, 0.4)'
          },
          '50%': {
            boxShadow: '0 0 0 10px rgba(59, 130, 246, 0)'
          }
        },
        'spin': {
          '0%': { transform: 'rotate(0deg)' },
          '100%': { transform: 'rotate(360deg)' }
        }
      },
      animation: {
        'slide-in-up-out-down': 'slide-in-up-out-down 5s ease-in-out forwards',
        'slide-in-from-left': 'slide-in-from-left var(--animation-duration) both',
        'fade-in-up': 'fade-in-up 0.6s ease-out forwards',
        'slide-in-from-left-custom': 'slide-in-from-left-custom 0.5s ease-out forwards',
        'scale-in': 'scale-in 0.4s ease-out forwards',
        'pulse-glow': 'pulse-glow 2s infinite',
        'spin': 'spin 1s linear infinite'
      }
    },
  }
}
