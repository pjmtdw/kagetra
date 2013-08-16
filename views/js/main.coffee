requirejs.config
  paths:
    zep_or_jq: "libs/zepto_or_jquery"
    jquery: "http://cdnjs.cloudflare.com/ajax/libs/jquery/1.9.1/jquery.min"
    jquery_placeholder: "http://cdnjs.cloudflare.com/ajax/libs/jquery-placeholder/2.0.7/jquery.placeholder.min"
    zepto: "http://cdnjs.cloudflare.com/ajax/libs/zepto/1.0/zepto.min"
    backbone: "http://cdnjs.cloudflare.com/ajax/libs/backbone.js/1.0.0/backbone-min"
    underscore: "http://cdnjs.cloudflare.com/ajax/libs/underscore.js/1.4.4/underscore-min"
    foundation: "http://cdnjs.cloudflare.com/ajax/libs/foundation/4.1.6/js/foundation/foundation"
    "foundation.topbar": "http://cdnjs.cloudflare.com/ajax/libs/foundation/4.1.6/js/foundation/foundation.topbar.min"
    "foundation.reveal": "http://cdnjs.cloudflare.com/ajax/libs/foundation/4.1.6/js/foundation/foundation.reveal.min"
    "foundation.dropdown": "http://cdnjs.cloudflare.com/ajax/libs/foundation/4.1.6/js/foundation/foundation.dropdown.min"
    "foundation.section": "http://cdnjs.cloudflare.com/ajax/libs/foundation/4.1.6/js/foundation/foundation.section.min"
    "foundation.alerts": "http://cdnjs.cloudflare.com/ajax/libs/foundation/4.1.6/js/foundation/foundation.alerts.min"
    "foundation.magellan": "http://cdnjs.cloudflare.com/ajax/libs/foundation/4.1.6/js/foundation/foundation.magellan.min"
    "foundation.tooltips": "http://cdnjs.cloudflare.com/ajax/libs/foundation/4.1.6/js/foundation/foundation.tooltips.min"
    modernizr: "http://cdnjs.cloudflare.com/ajax/libs/foundation/4.1.6/js/vendor/custom.modernizr.min"
    json2: "http://cdnjs.cloudflare.com/ajax/libs/json2/20121008/json2"
    select2: "http://cdnjs.cloudflare.com/ajax/libs/select2/3.4.0/select2.min"
    crypto: "libs/CryptoJS/crypto"
    require: "libs/require"
    "crypto-pbkdf2": "libs/CryptoJS/rollups/pbkdf2"
    "crypto-hmac": "libs/CryptoJS/rollups/hmac-sha256"
    "crypto-base64": "libs/CryptoJS/components/enc-base64-min"
    "crypto-aes": "libs/CryptoJS/rollups/aes"
    "crypto-core": "libs/CryptoJS/components/core"

  shim:
    jquery_placeholder: deps: ["zep_or_jq"]
    myutil: deps: ["underscore","zep_or_jq"]
    select2: deps: ["zep_or_jq"]
    schedule_item: deps: ["backbone"]
    jquery: exports: "$"
    underscore: exports: "_"
    crypto: exports: "CryptoJS"
    backbone:
      deps: ["zep_or_jq","underscore","json2"]
      exports: "Backbone"
    foundation: deps: ["zep_or_jq","modernizr"]
    "foundation.topbar": deps: ["foundation"]
    "foundation.reveal": deps: ["foundation"]
    "foundation.dropdown": deps: ["foundation"]
    "foundation.section": deps: ["foundation"]
    "foundation.alerts": deps: ["foundation"]
    "foundation.magellan": deps: ["foundation"]
    "foundation.tooltips": deps: ["foundation"]
    "crypto-hmac": deps: ["crypto"]
    "crypto-base64": deps: ["crypto"]
    "crypto-pbkdf2": deps: ["crypto"]
    "crypto-aes": deps: ["crypto"]

require ["zep_or_jq","myutil","backbone","select2","jquery_placeholder"
     "foundation.reveal","foundation.topbar","foundation.dropdown","foundation.section","foundation.alerts","foundation.magellan","foundation.tooltips"], ->
  # simply-deferred を使う場合は下記が必要
  # 現在は jquery の select2 プラグインを使用しているため zepto は使わない方針
  # zep_or_jq は常にjqueryを返すようになっている 
      
  # Deferred.installInto(Zepto) if Zepto?
  $ = require("zep_or_jq")
  init_f = ->
    # alert if ajax failed
    $(document).ajaxError((evt,xhr,settings,error)->
      return if xhr.status == 0
      alert("通信エラー(#{xhr.status}): #{xhr.statusText}"))

    # insert dummy element to detect whether it is small screen
    v = $("<div>",{class:'show-for-small'})
    v.insertAfter("body")
    window.is_small = v.is(":visible")
    v.remove()

    $(document).foundation()
  $(->
    hamls = $("body").data("haml")
    deferreds = []
    if hamls
      for b in hamls.split(/\s*,\s*/)
        continue unless b
        do ->
          d = new $.Deferred()
          v = $("<div>")
          d["haml"] = b
          v.load("haml/#{b}",->
            $("body").append(v)
            d.resolve()
          )
          deferreds.push(d.promise())
    when_loaded = ->
      mod_name = $("script[data-start]").data("start")
      if mod_name
        require [mod_name], (mod) -> init_f();mod.init()
    if deferreds.length > 0
      $.when.apply($,deferreds).done(when_loaded)
    else
      when_loaded()
  )
