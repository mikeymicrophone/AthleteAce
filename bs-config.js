// bs-config.js
module.exports = {
  proxy: "athleteace.test",
  files: [
    "app/views/**/*.html.erb",
    "app/helpers/**/*.rb",
    "app/assets/tailwind/components/*.css",
    "app/assets/javascripts/**/*.js"
  ],
  browser: "Google Chrome",
  notify: false
};
