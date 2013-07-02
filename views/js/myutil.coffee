define (require, exports, module) ->
  _ = require("underscore")
  $ = require("zep_or_jq")
  _.mixin
    router_base: (prefix,arg) ->
      Backbone.Router.extend
        remove_all: ->
          for k in arg
            window["#{prefix}_#{k}_view"]?.remove()
        set_id_fetch: (k,klass,id) ->
          v = new klass()
          window["#{prefix}_#{k}_view"] = v
          m = v.model
          if id?
            m.set("id",id).fetch()
          else
            m.fetch()

    pbkdf2_password: (pass, salt) ->
      CryptoJS.PBKDF2(pass,salt, {keySize: 256/32, iterations: 100}).toString(CryptoJS.enc.Base64)
    hmac_password: (pass,salt) ->
      secret = _.pbkdf2_password(pass,salt)
      hmac = CryptoJS.algo.HMAC.create(CryptoJS.algo.SHA256, secret)
      msg = CryptoJS.lib.WordArray.random(128/8).toString(CryptoJS.enc.Base64)
      hmac.update(msg)
      hash = hmac.finalize().toString(CryptoJS.enc.Base64)
      [hash, msg]
    # {{ hoge }} hoge をそのまま表示
    # {- hoge -} hoge を escape して表示
    template_braces: (x) ->
      _.template(x,false,{
        interpolate: /\{\{(.+?)\}\}/g,
        escape: /\{\-(.+?)\-\}/g})
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
      # submit失敗したときにエラーメッセージを表示しfalseを返す
      (arg...)->
        try
          _.bind(f,this)(arg...)
        catch e
          console.log e.message
          console.trace?()
        return false
    # ensure that view is removed when reveal is closed
    reveal_view: (target,view) ->
      $(target).one("closed", ->
        view.remove())
      $(target).foundation("reveal","open")
    
    make_checkbox: (checked,opts) ->
      # underscore.jsのtemplateとしてHamlを使うと %input(type='checkbox' {{ checked?"checked":"" }}) みたいなことができない
      o = _.extend({type:'checkbox'},opts)
      o["checked"] = "checked" if checked
      $("<input>",o)[0].outerHTML
    make_option: (selected,opts) ->
      opts = _.extend({selected:"selected"},opts) if selected

      $("<option>",opts)[0].outerHTML

    # save backbone model (only changed attributes)
    save_model_alert: (model,obj) ->
      defer = $.Deferred()
      _.save_model(model,obj).done(->
        alert("更新成功")
        defer.resolve()
      ).fail((error) ->
        alert("更新失敗: " + error)
        defer.reject(error))
      defer.promise()
    save_model: (model,obj)->
      m = model.clone()
      m.set(obj)
      attrs = {}
      if not m.isNew()
        attrs = m.changedAttributes()
        m.clear()
        m.set('id',model.id)
      defer = $.Deferred()
      m.save(attrs).done((data) ->
        if data._error_
          defer.reject(data._error_)
        else
          model.set(m.toJSON())
          model.trigger("sync")
          defer.resolve()
      )
      defer.promise()
  
  # b == true なら最初の状態, b == false なら裏状態
  # 指定されないならtoggle
  $.fn.toggleBtnText = (b)->
    curstate = (@data("toggle-state") != "toggled")
    if b?
      nextstate = b
    else
      nextstate ^= true
    if curstate == nextstate
      return
    if not curstate
      @data("toggle-state","toggled")
    t = @data("toggle-text")
    @data("toggle-text",@text())
    @text(t)

  # formのinput要素を{name: value}形式にする
  $.fn.serializeObj = ->
    o = {}
    a = this.serializeArray()
    $.each a, ->
      if o[this.name]?
        if !o[this.name].push
          o[this.name] = [o[this.name]]
        o[this.name].push(this.value || null)
      else
        o[this.name] = this.value || null
    # checkbox でチェックされていないものを集めてくる
    this.find("input[type='checkbox']:not(:checked)").each(->
      o[this.name] = null
    )
    o
