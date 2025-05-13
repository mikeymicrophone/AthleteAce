/**
 * Tailwind CSS Configuration – custom theme & paths
 * Docs: https://tailwindcss.com/docs/configuration
 */
module.exports = {
  content: [
    "./app/views/**/*.erb",
    "./app/helpers/**/*.rb",
    "./app/javascript/**/*.js",
    "./app/assets/**/*.css"
  ],
  theme: {
    extend: {
      colors: {
        brand: "#3b82f6",
        "brand-dark": "#2563eb"
      },
      fontFamily: {
        serif: ['Lora', 'serif']
      }
    }
  },
  plugins: []
};
