requirejs.config
  paths:
    jquery: "http://cdnjs.cloudflare.com/ajax/libs/jquery/1.9.1/jquery.min"
    zepto: "http://cdnjs.cloudflare.com/ajax/libs/zepto/1.0/zepto.min"
    backbone: "http://cdnjs.cloudflare.com/ajax/libs/backbone.js/1.0.0/backbone-min"
    underscore: "http://cdnjs.cloudflare.com/ajax/libs/underscore.js/1.4.4/underscore-min"
    foundation: "http://cdnjs.cloudflare.com/ajax/libs/foundation/4.1.2/js/foundation/foundation"
    "foundation.topbar": "http://cdnjs.cloudflare.com/ajax/libs/foundation/4.1.2/js/foundation/foundation.topbar.min"
    modernizr: "http://cdnjs.cloudflare.com/ajax/libs/foundation/4.1.2/js/vendor/custom.modernizr.min"
    json2: "http://cdnjs.cloudflare.com/ajax/libs/json2/20121008/json2"
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
      deps: ["jquery","underscore","json2"]
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
