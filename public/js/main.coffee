requirejs.config
  paths:
    jquery: "libs/jquery"
    backbone: "libs/backbone"
    underscore: "libs/underscore"
    modernizr: "libs/modernizr"
    foundation: "libs/foundation/foundation"
    "foundation.topbar": "libs/foundation/foundation.topbar"
    crypto: "libs/CryptoJS/crypto"
    "crypto-pbkdf2": "libs/CryptoJS/rollups/pbkdf2"
    "crypto-hmac": "libs/CryptoJS/rollups/hmac-sha256"
    "crypto-base64": "libs/CryptoJS/components/enc-base64-min"
    "crypto-core": "libs/CryptoJS/components/core"
  shim:
    jquery:
      exports: "$"
    underscore:
      exports: "_"
    crypto:
      exports: "CryptoJS"
    backbone:
      deps: ["jquery","underscore","libs/json2"]
      exports: "Backbone"
    foundation:
      deps: ["jquery","modernizr"]
    "foundation.topbar":
      deps: ["foundation"]
    "crypto-hmac":
      deps: ["crypto"]
    "crypto-base64":
      deps: ["crypto"]
    "crypto-pbkdf2": 
      deps: ["crypto"]

require ["jquery","foundation","backbone"], -> 
  $ = require("jquery")
  mod_name = $("script[data-start]").attr("data-start")
  if mod_name
    require [mod_name], (mod) -> mod()
