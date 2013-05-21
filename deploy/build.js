({
  baseUrl: './',
  appDir: "../views/js",
  mainConfigFile: '../views/js/main.js',
  dir: '../public/js/',
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
