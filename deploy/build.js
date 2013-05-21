({
  baseUrl: './',
  appDir: "../public/js",
  mainConfigFile: '../public/js/main.js',
  dir: '../public/js_dist/',
  logLevel: 0,
  preserveLicenseComments: false,
  modules: [
    { name: "main" },
    { name: "top",
      exclude: ["main"] },
    { name: "login",
      exclude: ["main"] }
  ]
})
