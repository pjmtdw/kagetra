define (require, exports, module) ->
  _ = require("underscore")
  $ = require("zep_or_jq")
  # 前半はURL,後半はメールアドレスにマッチ
  # メールアドレスにマッチする部分は PEAR::Mail_RFC822::isValidInetAddress()
  pat_url = new RegExp("((https?://[a-zA-Z0-9/:%#$&?()~.=+_-]+)|(([*+!.&#\$|\'\\%\/0-9a-z^_`{}=?~:-]+)@(([0-9a-z-]+\.)+[0-9a-z]{2,})))","gi")
  _.mixin
    replace_url_escape: (s)->
      return "" if _.isEmpty(s)
      offset = 0
      r = ""
      while mat = pat_url.exec(s)
        r += _.escape(s.substring(offset,mat.index))
        if not _.isEmpty(mat[2])
          r += "<a href='#{mat[0]}' target='_blank'>#{mat[0]}</a>"
        else
          r += "<a href='mailto:#{mat[0]}'>#{mat[0]}</a>"
        offset = pat_url.lastIndex
      r += _.escape(s.substring(offset))
      r

      
    is_public_mode: ->
      location.pathname.indexOf("/public/") == 0
    router_base: (prefix,arg) ->
      Backbone.Router.extend
        remove_all: ->
          for k in arg
            vn = "#{prefix}_#{k}_view"
            window[vn]?.remove()
            delete window[vn]
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
    make_option: (select_val,opts) ->
      opts = _.extend({selected:"selected"},opts) if (select_val?.toString() == opts.value.toString())

      $("<option>",opts)[0].outerHTML

    album_thumb: (x) ->
      "<a href='album#item/#{x.id}' data-id='#{x.id}'>" +
        "<img src='/static/album/thumb/#{x.thumb.id}' style='width:#{x.thumb.width}px;height:#{x.thumb.height}px' />" +
      "</a>"


    # save backbone model (only changed attributes)
    # force: list of keys to be saved even if not changed
    save_model_alert: (model,obj,force) ->
      defer = $.Deferred()
      _.save_model(model,obj,force).done(->
        alert("更新成功")
        defer.resolve()
      ).fail((error) ->
        alert("更新失敗: " + error)
        defer.reject(error))
      defer.promise()
    save_model: (model,obj,force)->
      m = model.clone()
      m.set(obj)
      attrs = {}
      if not m.isNew()
        attrs = m.changedAttributes() || {}
        if force
          attrs = _.extend(attrs,m.pick(force))
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


  $.fn.scrollHere = (speed)->
    speed ||= 1000
    $('html, body').animate({
      scrollTop: this.offset().top
    }, speed)


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
    # checkboxでチェックされていないものは
    # serializeArrayに出て来ないので自分で集めてくる
    this.find("input[type='checkbox']").each(->
      o[this.name] = $(this).is(":checked")
      true
    )
    o
