requirejs.config
  paths:
    jquery: "libs/jquery/dist/jquery"
    jquery_placeholder: "libs/jquery-placeholder/jquery.placeholder"
    colorbox: "libs/jquery-colorbox/jquery.colorbox"
    backbone: "libs/backbone/backbone"
    underscore: "libs/underscore/underscore"
    foundation: "libs/foundation/js/foundation/foundation"
    "foundation.topbar": "libs/foundation/js/foundation/foundation.topbar"
    "foundation.reveal": "libs/foundation/js/foundation/foundation.reveal"
    "foundation.dropdown": "libs/foundation/js/foundation/foundation.dropdown"
    "foundation.section": "libs/foundation/js/foundation/foundation.section"
    "foundation.alerts": "libs/foundation/js/foundation/foundation.alerts"
    "foundation.magellan": "libs/foundation/js/foundation/foundation.magellan"
    "foundation.tooltips": "libs/foundation/js/foundation/foundation.tooltips"
    modernizr: "libs/foundation/js/vendor/custom.modernizr"
    json2: "libs/json2/json2"
    select2: "libs/select2/select2.min"
    require: "libs/requirejs/require"
    "crypto-pbkdf2": "libs/crypto-js/rollups/pbkdf2"
    "crypto-hmac": "libs/crypto-js/rollups/hmac-sha256"
    "crypto-base64": "libs/crypto-js/components/enc-base64-min"
    "crypto-aes": "libs/crypto-js/rollups/aes"
    "crypto-core": "libs/crypto-js/components/core"

  shim:
    jquery_placeholder: deps: ["jquery"]
    colorbox: deps: ["jquery"]
    myutil: deps: ["underscore","jquery","backbone"]
    select2: deps: ["jquery"]
    blockui: deps: ["jquery"]
    schedule_item: deps: ["backbone"]
    jquery: exports: "$"
    underscore: exports: "_"
    crypto: exports: "CryptoJS"
    backbone:
      deps: ["jquery","underscore","json2"]
      exports: "Backbone"
    foundation: deps: ["jquery","modernizr"]
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

require ["jquery","backbone","myutil","select2","colorbox","jquery_placeholder",
     "foundation.reveal","foundation.topbar","foundation.dropdown","foundation.section",
     "foundation.alerts","foundation.magellan","foundation.tooltips"], ->
  $ = require("jquery")
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
    # magellanは掲示板のみで使われ，そこで初期化するのでここではしなくてもいい．
    # revealの背景をclickしたときの処理は自前で行う．
    # という訳なので reveal を使うときは必ず myutil.coffee の _.reveal_view() を使うこと．
    $(document).foundation('topbar dropdown section alerts tooltips')
    .foundation('reveal',closeOnBackgroundClick:false,dismissModalClass:'my-close-reveal-modal')

  $(->
    hamls = $("body").data("haml")
    deferreds = []
    if hamls
      for b in hamls.split(/\s*,\s*/)
        continue unless b
        do ->
          d = $.Deferred()
          v = $("<div>")
          d["haml"] = b
          v.load("haml/#{b}",->
            $("#body-end").before(v)
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
