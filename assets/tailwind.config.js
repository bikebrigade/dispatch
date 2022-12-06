// See the Tailwind configuration guide for advanced usage
// https://tailwindcss.com/docs/configuration

const defaultTheme = require('tailwindcss/defaultTheme')
const plugin = require("tailwindcss/plugin")

module.exports = {
  content: [
    './js/**/*.js',
    '../lib/*_web.ex',
    '../lib/*_web/**/*.*ex'
  ],
  safelist: ['tribute-container'],
  theme: {
    extend: {
      spacing: {
        '128': '32rem',
      },
      screens: {
        'print': {
          'raw': 'print'
        },
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

    plugin(({
      addVariant
    }) => addVariant("phx-no-feedback", [".phx-no-feedback&", ".phx-no-feedback &"])),
    plugin(({
      addVariant
    }) => addVariant("phx-click-loading", [".phx-click-loading&", ".phx-click-loading &"])),
    plugin(({
      addVariant
    }) => addVariant("phx-submit-loading", [".phx-submit-loading&", ".phx-submit-loading &"])),
    plugin(({
      addVariant
    }) => addVariant("phx-change-loading", [".phx-change-loading&", ".phx-change-loading &"]))
  ]

}