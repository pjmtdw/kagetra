define (require, exports, module) ->
  _ = require("underscore")
  $ = require("zep_or_jq")
  Backbone = require("backbone")

  # 履歴付きBackbone.Router
  class HistoryRouter extends Backbone.Router
    initialize: (options)->
      @on "route", @storeRoute
      @history = []
      super options
    storeRoute: (ev)->
      @history.push Backbone.history.fragment
      @history.shift() if @history.length > 2
    previous: ->
      @history[0]

  # 前半はURL,後半はメールアドレスにマッチ
  # メールアドレスにマッチする部分は PEAR::Mail_RFC822::isValidInetAddress()
  pat_url = new RegExp("((https?://[a-zA-Z0-9/:%#$&?()~.=+_-]+)|(([*+!.&#\$|\'\\%\/0-9a-z^_`{}=?~:-]+)@(([0-9a-z-]+\.)+[0-9a-z]{2,})))","gi")
  _.mixin
    ie9_placeholder: (target)->
      return unless g_is_ie9?
      # Internet Explorer 9 does not support placeholder
      for s in ["input[type='text']","input[type='password']","textarea"]
        $(target).find(s).placeholder()

    iframe_submit: (when_success,when_error)->
      contents = $("#dummy-iframe").contents()
      return unless contents.find("body").html() # IEの場合は最初の読み込み時にもloadがtriggerされる
      html = contents.find("#response").html()
      if not html
        alert("エラー: #{contents.find("title").text()}")
        when_error?()
        return
      try
        res = JSON.parse(html)
        if res._error_
          alert(res._error_)
          when_error?()
        else if res.result == "OK"
          alert("送信しました")
          when_success?(res)
        else
          alert("エラー: 送信失敗(1)")
      catch e
        alert("エラー: 送信失敗(2)")

    show_kind_symbol: (kind,official) ->
      s = switch kind
            when "contest"
              if official then "spades" else "clubs"
            when "party"
              "hearts"
            else
              "diams"
      "<span class='event-symbol #{s}'>&#{s};</span>"
    to_int_if_digit: (s)->
      # $("hoge").val() は String を返すのでそれを Int にする
      return "" if s.length == 0
      if isNaN(s) then s else parseInt(s)
    show_prize: (s) ->
      r = []
      ss = s.prize
      if s.point then r.push "#{s.point}pt"
      if s.point_local then r.push "#{s.point_local}kpt"
      if r.length > 0
        ss += " [#{r.join(",")}]"
      ss
    result_str: (s) ->
      {win: '○'
      lose: '●'
      now: '対戦中'
      default_win: '不戦'
      }[s]
    # reverse of $.param
    deparam: (s) ->
      _.object(
        for p in s.split('&')
         p.split('=')
      )

    swap_elem: (a,b) ->
      ai = a.index()
      bi = b.index()
      return if ai == bi
      tmp = a.clone()
      if ai > bi
        b.before(tmp)
      else
        b.after(tmp)
      a.remove()

    user_name_with_real_name: (data)->
      un = _.escape(data.user_name)
      rn = if data.real_name then "(#{_.escape(data.real_name)})"
      un + (rn ? "")

    confirm_change_password: (args)->
      try
        el = args.el
        salt_new = null
        first = ->
          $.get args.url_salt
        second = (data)->
          [hash, msg] = _.hmac_password(el.find(args.cur).val(),data.salt_cur)
          salt_new = data.salt_new
          $.post args.url_confirm,
            hash: hash
            msg: msg
        third = (data)->
          defer = $.Deferred()
          if salt_new == null
            return defer.reject("saltが空です")
          if data.result == 'OK'
            npass = el.find(args.new_1).val()
            if npass.length == 0
              return defer.reject("新パスワードが空白です")
            if npass != el.find(args.new_2).val()
              return defer.reject("再確認のパスワードが一致しません")
            hash = _.pbkdf2_password(npass,salt_new)
            $.post args.url_change,
              hash: hash
              salt: salt_new
          else
            defer.reject("現在のパスワードが違います")
        fourth = (data) ->
          defer = $.Deferred()
          if data.result == 'OK'
            defer.resolve("パスワードを変更しました")
          else
            defer.reject(data)
        $.when(first()).then(second).then(third).then(fourth)
          .done((data) -> alert("成功: " + data))
          .fail((data) -> alert("失敗: " + data);console.log data)
        false
      catch e
        console.log e.message
        alert e.message
        false
    show_new_comment: (data)->
      c = if data.has_new_comment
        " <span class='new-comment'>new</span>"
      else
        ""
      "( <span class='comment-count'>#{data.comment_count}</span>#{c} )"
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


    router_base: (prefix,arg) ->
      HistoryRouter.extend
        remove_all: (ignore)->
          for k in arg when k != ignore
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
    # revealが閉じたときにviewがremoveされることを保証する
    # ついでにrevealのcloseを途中でキャンセルする方法が見つからなかったため
    # 背景をclickしたときの処理は自前で行なう
    # TODO: 将来的にZurb Foundationがバージョンアップしたらその方法が用意されるかもしれない
    reveal_view: (target,view,confirm_when_edited) ->
      obj = $(target)
      obj.one("closed", ->
        $(".reveal-modal-bg").off('click')
        view.remove()
        obj.empty()
        obj.removeClass("form-changed")
      )
      # 
      obj.one("opened", ->
        $(".reveal-modal-bg").on('click',->
          if obj.hasClass("form-changed") and not confirm("本当に変更を破棄して閉じますか？")
            return
          obj.foundation("reveal","close")
        )
      )
      if confirm_when_edited
        obj.one("change",":input",->obj.addClass("form-changed"))
      obj.foundation("reveal","open")

    make_checkbox: (checked,opts) ->
      # underscore.jsのtemplateとしてHamlを使うと %input(type='checkbox' {{ checked?"checked":"" }}) みたいなことができない
      o = _.extend({type:'checkbox'},opts)
      o["checked"] = "checked" if checked
      $("<input>",o)[0].outerHTML
    make_option: (select_val,opts) ->
      opts = _.extend({selected:"selected"},opts) if (select_val?.toString() == opts.value.toString())

      $("<option>",opts)[0].outerHTML

    album_thumb: (x,new_window) ->
      target = if new_window then "target='_blank'" else ""
      "<a #{target} href='album#item/#{x.id}' data-id='#{x.id}'>" +
        "<img src='/static/album/thumb/#{x.thumb.id}.#{x.rotate}' style='width:#{x.thumb.width}px;height:#{x.thumb.height}px' />" +
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
    if not nextstate
      @data("toggle-state","toggled")
    t = @data("toggle-text")
    @data("toggle-text",@text())
    @text(t)

  $.fn.fillForm = (obj)->
    for k,v of obj
      @.find("[name='#{k}']").val(v)

  $.fn.scrollHere = (speed,offset)->
    return unless @.length > 0
    speed ||= 1000
    top = @offset().top + (offset || 0)
    if speed < 0
      $('html, body').scrollTop(top)
    else
      $('html, body').animate({
        scrollTop: top
      }, speed)


  # formのinput要素を{name: value}形式にする
  $.fn.serializeObj = ->
    o = {}
    a = this.serializeArray()

    # multipleのselectで一つもチェックされてないものは
    # serializeArrayに出てこないので自分で集めてくる
    this.find("select[multiple]").each(->
      o[this.name] = []
      true
    )

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
