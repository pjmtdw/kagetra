({
  baseUrl: './',
  appDir: "../views/js",
  mainConfigFile: '../views/js/main.js',
  dir: '../public/js/',
  logLevel: 0,
  preserveLicenseComments: false,
  paths: {
    jquery: "empty:",
    zepto: "empty:",
    backbone: "empty:",
    underscore: "empty:",
    foundation: "empty:",
    "foundation.topbar": "empty:",
    modernizr: "empty:",
    json2: "empty:"
  },
  modules: [
    { name: "main" },
    { name: "top",
      exclude: ["main"] },
    { name: "login",
      exclude: ["main"] }
  ]
})
