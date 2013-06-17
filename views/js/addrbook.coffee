define ["crypto-aes"], ->
  AddrBookRouter = Backbone.Router.extend
    routes:
      "user/:id": "user"
    user: (uid) ->
      window.addrbook_view.refresh(parseInt(uid))
  AddrBookPanelModel = Backbone.Model.extend
    urlRoot: "/api/user/list"
  AddrBookPanelView = Backbone.View.extend
    el: "#addrbook-panel"
    template: _.template_braces($("#templ-addrbook-panel").html())
    events:
      "change #panel-initials": "refresh"
      "change #panel-users": "refresh_body"
    initialize: ->
      _.bindAll(this,"render","refresh")
      @model = new AddrBookPanelModel()
      @model.bind("sync", @render, this)
      @model.set("id",0)
      @model.fetch()
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
    urlRoot: "/api/addrbook/item"
  AddrBookView = Backbone.View.extend
    el: "#addrbook-body"
    template_enc: _.template($("#templ-addrbook-body-enc").html())
    template: _.template($("#templ-addrbook-body").html())

    initialize: ->
      @model = new AddrBookModel()
      @model.bind("sync", @render, this)
    render: ->
      text = @model.get("text")
      dec = CryptoJS.AES.decrypt(text,$("#password").val())
      data = JSON.parse(dec.toString(CryptoJS.enc.Utf8))
      
      @$el.html(@template(data:data))
    refresh: (id) ->
      @model.set("id",id)
      @model.fetch()

  init: ->
    window.addrbook_router = new AddrBookRouter()
    window.addrbook_view = new AddrBookView()
    window.addrbook_panel = new AddrBookPanelView()
    Backbone.history.start()
