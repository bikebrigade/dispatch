const defaultTheme = require('tailwindcss/defaultTheme')

module.exports = {
  purge: {
    content: [
      '../**/*.ex',
      '../**/*.eex',
      '../**/*.leex',
      '../**/*.heex',
      './js/**/*.js'
    ],
    options: {
      safelist: ['tribute-container']
    }
  },
  theme: {
    extend: {
      screens: {
        'print': {'raw': 'print'},
      },
      fontFamily: {
        sans: ['Inter var', ...defaultTheme.fontFamily.sans],
      }
    },
  },
  plugins: [
    require('@tailwindcss/forms'),
    require('@tailwindcss/typography'),
    require('@tailwindcss/aspect-ratio'),
  ],
}