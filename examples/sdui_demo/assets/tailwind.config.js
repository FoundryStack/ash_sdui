module.exports = {
  content: [
    './js/**/*.js',
    '../lib/**/*_web.ex',
    '../lib/**/*_web/**/*.{ex,heex}',
  ],
  theme: {
    extend: {},
  },
  plugins: [
    require('daisyui'),
  ],
}
