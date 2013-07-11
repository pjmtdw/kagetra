define ["crypto-aes", "crypto-hmac","crypto-pbkdf2","crypto-base64"], ->
  validations = [
    ["名前",/^\s*\S+\s+\S+\s*$/,"名前の姓と名の間に空白を入れて下さい"]
    ["ふりがな",/^\s*\S+\s+\S+\s*$/,"ふりがなの姓と名の間に空白を入れて下さい"]
  ]
  check_password = (pass) ->
    g_confirm_str == CryptoJS.AES.decrypt(g_confirm_enc,pass).toString(CryptoJS.enc.Latin1)
  AddrBookRouter = Backbone.Router.extend
    routes:
      "user/:id": "user"
      "": "start"
    initialize: ->
      _.bindAll(@,"start")
    start: -> @navigate("user/#{g_myid}",{trigger:true,replace:true})
    user: (uid) ->
      window.addrbook_view.refresh(uid)
  AddrBookPanelModel = Backbone.Model.extend
    urlRoot: "api/user/auth/list"
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
        if not window.addrbook_view.decode_success
          window.addrbook_view.render()
      else
        alert("名簿パスワードが違います")
      false
    initialize: ->
      _.bindAll(this,"render","refresh")
      @model = new AddrBookPanelModel()
      @listenTo(@model,"sync", @render)
      @model.set("id",0)
      @model.fetch()
      $("#panel-users").attr("size","1") if window.is_small
    refresh_body: (ev) ->
      v = $(ev.currentTarget).val()
      window.addrbook_router.navigate("user/#{v}",{trigger:true})
    render: ->
      $("#panel-users").html(@template(data:@model.toJSON()))
      $("#panel-users").scrollTop(0,0)
    refresh: (ev)->
      v = $(ev.currentTarget).val()
      @model.set("id",v)
      @model.fetch()

  AddrBookModel = Backbone.Model.extend
    url: -> "api/addrbook/item/#{@.get('uid')}"
  AddrBookView = Backbone.View.extend
    el: "#addrbook-body"
    events:
      "submit #addrbook-form":"do_when_submit"
    do_when_submit: _.wrap_submit ->
      obj = $("#addrbook-form").serializeObj()
      for [key,patt,msg] in validations
        if not patt.test(obj[key])
          alert(msg)
          return
      json = JSON.stringify(obj)
      pass = $("#password").val()
      if pass.length == 0
        alert("名簿パスワードを入力して下さい")
        $("#password").focus()
        return false
      else if not check_password(pass)
        alert("名簿パスワードが違います")
        $("#password").focus()
        return false
      text = CryptoJS.AES.encrypt(json,pass).toString(CryptoJS.enc.BASE64)
      @model.set("text",text)
      @model.set("found",true) # AddrBookViwe が render するときに text の方を使う
      @model.save().done(-> alert("更新しました"))

    template_enc: _.template($("#templ-addrbook-body-enc").html())
    template_edit: _.template_braces($("#templ-addrbook-body-edit").html())
    template: _.template($("#templ-addrbook-body").html())

    initialize: ->
      _.bindAll(this,"render","do_when_submit")
      @model = new AddrBookModel()
      @listenTo(@model,"sync", @render)
    render: ->
      res = null
      @decode_success = false
      if @model.get("found")
        text = @model.get("text")
        pass = $("#password").val()
        if pass.length == 0
          $("#addrbook-body").text("名簿パスワードを入力して下さい")
          $("#password").focus()
          return
        dec = CryptoJS.AES.decrypt(text,pass)
        try
          res = JSON.parse(dec.toString(CryptoJS.enc.Utf8))
        catch e
          # TODO: Malformed UTF-8 data ではなく，ハッシュ値の確認などの方法で復号失敗を検知する
          console.log e.message
          $("#addrbook-body").text("復号失敗．おそらく名簿パスワードが違います．")
          return
      else
        res = _.clone(@model.get("default"))

      data = []
      for k in window.addrbook_keys
        data.push [k,res[k]]
        delete res[k]
      for k,v of res
        data.push [k,v]
      
      templ = if @model.get("editable") then @template_edit else @template
      @$el.html(templ(data:data))
      @decode_success = true
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
