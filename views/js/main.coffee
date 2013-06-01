requirejs.config
  paths:
    zep_or_jq: "libs/zepto_or_jquery"
    jquery: "http://cdnjs.cloudflare.com/ajax/libs/jquery/1.9.1/jquery.min"
    zepto: "http://cdnjs.cloudflare.com/ajax/libs/zepto/1.0/zepto.min"
    backbone: "http://cdnjs.cloudflare.com/ajax/libs/backbone.js/1.0.0/backbone-min"
#    underscore: "http://cdnjs.cloudflare.com/ajax/libs/underscore.js/1.4.4/underscore-min"
    underscore: "http://cdnjs.cloudflare.com/ajax/libs/underscore.js/1.4.4/underscore"
    foundation: "http://cdnjs.cloudflare.com/ajax/libs/foundation/4.1.2/js/foundation/foundation"
    "foundation.topbar": "http://cdnjs.cloudflare.com/ajax/libs/foundation/4.1.2/js/foundation/foundation.topbar.min"
    "foundation.reveal": "http://cdnjs.cloudflare.com/ajax/libs/foundation/4.1.2/js/foundation/foundation.reveal.min"
    modernizr: "http://cdnjs.cloudflare.com/ajax/libs/foundation/4.1.2/js/vendor/custom.modernizr.min"
    json2: "http://cdnjs.cloudflare.com/ajax/libs/json2/20121008/json2"
    deferred: "libs/deferred.min"
    crypto: "libs/CryptoJS/crypto"
    "crypto-pbkdf2": "libs/CryptoJS/rollups/pbkdf2"
    "crypto-hmac": "libs/CryptoJS/rollups/hmac-sha256"
    "crypto-base64": "libs/CryptoJS/components/enc-base64-min"
    "crypto-core": "libs/CryptoJS/components/core"
  shim:
    myutil:
      deps: ["underscore","zep_or_jq"]
    jquery:
      exports: "$"
    underscore:
      exports: "_"
    crypto:
      exports: "CryptoJS"
    backbone:
      deps: ["zep_or_jq","underscore","json2"]
      exports: "Backbone"
    foundation:
      deps: ["zep_or_jq","modernizr"]
    "foundation.topbar":
      deps: ["foundation"]
    "foundation.reveal":
      deps: ["foundation"]
    "crypto-hmac":
      deps: ["crypto"]
    "crypto-base64":
      deps: ["crypto"]
    "crypto-pbkdf2":
      deps: ["crypto"]

require ["zep_or_jq","myutil","deferred","foundation.reveal","foundation.topbar","backbone"], ->
  $ = require("zep_or_jq")
  Deferred.installInto(Zepto) if Zepto?
  init_f = ->
    # insert dummy element to detect whether it is small screen
    v = $("<div class='show-for-small'></div>")
    v.insertAfter("body")
    window.is_small = v.is(":visible")
    v.remove()

    $(document).foundation()
  mod_name = $("script[data-start]").attr("data-start")
  if mod_name
    require [mod_name], (mod) -> $( -> init_f();mod.init() )
