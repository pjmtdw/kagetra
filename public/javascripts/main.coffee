requirejs.config
  paths:
    jquery: "libs/jquery"
    foundation: "libs/foundation/foundation"
    "foundation.alerts": "libs/foundation/foundation.alerts"
    "crypto-pbkdf2": "libs/CryptoJS/rollups/pbkdf2"
    "crypto-hmac": "libs/CryptoJS/rollups/hmac-sha256"
    "crypto-base64": "libs/CryptoJS/components/enc-base64-min"
    "crypto-core": "libs/CryptoJS/components/core"
  shim:
    jQuery:
      exports: "$"
    crypto:
      exports: "CryptoJS"
    foundation:
      deps: ["jquery"]
    "foundation.alerts":
      deps: ["foundation"]
    login:
      deps: ["jquery", "foundation.alerts",
             "crypto-hmac", "crypto-base64", "crypto-pbkdf2"]
    "crypto-hmac":
      deps: ["crypto"]
    "crypto-base64":
      deps: ["crypto"]
    "crypto-pbkdf2": 
      deps: ["crypto"]

define 'crypto',["crypto-core"], -> CryptoJS

require ["login"],
  (main) -> main()
