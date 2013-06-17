define ["crypto-aes", "crypto-hmac","crypto-pbkdf2","crypto-base64"], ->
  check_password = (pass) ->
    g_confirm_str == CryptoJS.AES.decrypt(g_confirm_enc,pass).toString(CryptoJS.enc.Latin1)
  AddrBookRouter = Backbone.Router.extend
    routes:
      "user/:id": "user"
      "": -> window.addrbook_router.navigate("user/#{g_myid}",{trigger:true,replace:true})
    user: (uid) ->
      window.addrbook_view.refresh(uid)
  AddrBookPanelModel = Backbone.Model.extend
    urlRoot: "/api/user/list"
  AddrBookPanelView = Backbone.View.extend
    el: "#addrbook-panel"
    template: _.template_braces($("#templ-addrbook-panel").html())
    events:
      "change #panel-initials": "refresh"
      "change #panel-users": "refresh_body"
      "submit #panel-form": "do_when_submit"
    do_when_submit: ->
      pass = $("#password").val()
      if check_password(pass)
        alert("名簿パスワードは正しいです")
        window.addrbook_view.render()
      else
        alert("名簿パスワードが違います")
      false
    initialize: ->
      _.bindAll(this,"render","refresh")
      @model = new AddrBookPanelModel()
      @model.bind("sync", @render, this)
      @model.set("id",0)
      @model.fetch()
      $("#panel-users").attr("size","1") if window.is_small
    refresh_body: (ev) ->
      v = $(ev.currentTarget).val()
      window.addrbook_router.navigate("user/#{v}",{trigger:true})
    render: ->
      $("#panel-users").html(@template(data:@model.toJSON()))
    refresh: (ev)->
      v = $(ev.currentTarget).val()
      @model.set("id",v)
      @model.fetch()

  AddrBookModel = Backbone.Model.extend
    url: -> "/api/addrbook/item/#{@.get('uid')}"
  AddrBookView = Backbone.View.extend
    el: "#addrbook-body"
    events:
      "submit #addrbook-form":"do_when_submit"
    do_when_submit: ->
      try
        obj = $("#addrbook-form").serializeObj()
        json = JSON.stringify(obj)
        pass = $("#password").val()
        if not check_password(pass)
          alert("名簿パスワードが違います")
          return false
        text = CryptoJS.AES.encrypt(json,pass).toString(CryptoJS.enc.BASE64)
        @model.set("text",text)
        @model.save().done(-> alert("更新しました"))
      catch e
        console.log e.message
      false

    template_enc: _.template($("#templ-addrbook-body-enc").html())
    template_edit: _.template_braces($("#templ-addrbook-body-edit").html())
    template: _.template($("#templ-addrbook-body").html())

    initialize: ->
      _.bindAll(this,"do_when_submit")
      @model = new AddrBookModel()
      @model.bind("sync", @render, this)
    render: ->
      res = null
      if @model.get("found")
        text = @model.get("text")
        dec = CryptoJS.AES.decrypt(text,$("#password").val())
        try
          res = JSON.parse(dec.toString(CryptoJS.enc.Utf8))
        catch e
          # TODO: Malformed UTF-8 data ではなく，ハッシュ値の確認などの方法で復号失敗を検知する
          $("#addrbook-body").text("復号失敗: " + e.message)
          return
      else
        res = @model.get("default")

      data = []
      for k in window.addrbook_keys
        data.push [k,res[k]]
        delete res[k]
      for k,v of res
        data.push [k,v]
      
      templ = if @model.get("editable") then @template_edit else @template
      @$el.html(templ(data:data))
    refresh: (id) ->
      @model.clear()
      @model.set("uid",id)
      @model.fetch()

  init: ->
    window.addrbook_router = new AddrBookRouter()
    window.addrbook_view = new AddrBookView()
    window.addrbook_panel = new AddrBookPanelView()
    window.addrbook_keys = JSON.parse(g_keys_str)
    Backbone.history.start()
