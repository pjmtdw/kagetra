requirejs.config
  paths:
    jquery: "libs/jquery"
    foundation: "libs/foundation/foundation"
    "foundation.alerts": "libs/foundation/foundation.alerts"
    "crypto-pbkdf2": "libs/CryptoJS/rollups/pbkdf2"
    "crypto-hmac": "libs/CryptoJS/rollups/hmac-sha256"
    "crypto-base64": "libs/CryptoJS/components/enc-base64-min"
  shim:
    foundation:
      deps: ["jquery"]
    "foundation.alerts":
      deps: ["foundation"]
    login:
      deps: ["foundation.alerts"]

define 'crypto',["crypto-pbkdf2","crypto-hmac","crypto-base64"], -> CryptoJS

require ["login"],
  (main) -> main()
