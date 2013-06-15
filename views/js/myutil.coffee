define (require, exports, module) ->
  _ = require("underscore")
  $ = require("zep_or_jq")
  _.mixin
    pbkdf2_password: (pass, salt) ->
      CryptoJS.PBKDF2(pass,salt, {keySize: 256/32, iterations: 100}).toString(CryptoJS.enc.Base64)
    hmac_password: (pass,salt) ->
      secret = _.pbkdf2_password(pass,salt)
      hmac = CryptoJS.algo.HMAC.create(CryptoJS.algo.SHA256, secret)
      msg = CryptoJS.lib.WordArray.random(128/8).toString(CryptoJS.enc.Base64)
      hmac.update(msg)
      hash = hmac.finalize().toString(CryptoJS.enc.Base64)
      [hash, msg]
    result_str: (s) ->
      {win: '○'
      lose: '●'
      now: '対戦中'
      default_win: '不戦'
      }[s]
    show_opponent_belongs: (team_size,s) ->
      return "" unless s
      r = []
      if team_size == 1
        r.push s
      else
        r.push s.opponent_belongs if s.opponent_belongs
        r.push(switch s.opponent_order
          when 1 then "主将"
          when 2 then "副将"
          else "#{s.opponent_order}将") if s.opponent_order?
      "(#{r.join("・")})" if r.length > 0
    template_braces: (x) ->
      _.template(x,false,interpolate: /\{\{(.+?)\}\}/g)
    gen_date: (args...) ->
      ymd = ["year","mon","day"]
      [year,mon,day] =
        if args.length == 1
          if args[0].get?
            args[0].get(x) for x in ymd
          else
            args[0][x] for x in ymd
        else
          args
      new Date(year,mon-1,day)
    weekday_ja: ->
      ["日","月","火","水","木","金","土"]
    wrap_submit: (f) ->
      ->
        try
          _.bind(f,this)()
        catch e
          console.log e.message
        return false
  $.fn.toggleBtnText = ->
    a = "data-toggle-text"
    t = this.attr(a)
    this.attr(a,this.text())
    this.text(t)

  $.fn.serializeObj = ->
    o = {}
    a = this.serializeArray()
    $.each a, ->
      if o[this.name]?
        if !o[this.name].push
          o[this.name] = [o[this.name]]
        o[this.name].push(this.value || '')
      else
        o[this.name] = this.value || ''
    o
