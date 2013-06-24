define ->
  AlbumRouter = Backbone.Router.extend
    removeall: ->
      for s in ["top","year","group","item"]
        window["album_#{s}_view"]?.remove()
    set_id_fetch: (prefix,klass,id) ->
      @removeall()
      v = new klass()
      window["album_#{prefix}_view"] = v
      v.model.set("id",id).fetch()
    routes:
      "year/:year" : "year"
      "group/:id" : "group"
      "item/:id" : "item"
      "" : "start"
    year: (year) -> @set_id_fetch("year",AlbumYearView,year)
    group: (id) -> @set_id_fetch("group",AlbumGroupView,id)
    item: (id) -> @set_id_fetch("item",AlbumItemView,id)
    start: ->
      @removeall()
      v = new AlbumTopView()
      window.album_top_view = v
      v.model.fetch()

  AlbumTopModel = Backbone.Model.extend
    url: "/api/album/years"

  AlbumTopView = Backbone.View.extend
    template: _.template_braces($("#templ-album-top").html())
    events:
      "click .gbase.year": "do_list_year"
    do_list_year: (ev)->
      year = $(ev.currentTarget).data("year")
      window.album_router.navigate("year/#{year}", trigger:true)

    initialize: ->
      @model = new AlbumTopModel()
      @listenTo(@model,"sync",@render) # View.remove() したときにちゃんと stopListening されるように @model.bind() じゃなくて .listenTo() の方を使う

    render: ->
      @$el.html(@template(data:@model.toJSON()))
      # el:"#album-top" にして @$el.append(...) すると View.remove() するときに #album-top も一緒に消えてしまい
      # 次に render しようとしても #album-top がないためそれに append() できない
      # なので代わりに el には何も設定せず (デフォルトで <div> ) #album-top に appendTo する
      @$el.appendTo("#album-top")

  AlbumYearModel =  Backbone.Model.extend
    urlRoot: "/api/album/year"

  AlbumYearView = Backbone.View.extend
    events:
      "click .gbase.group": "goto_group"
      "click .gbase.item": "goto_item"
    goto_group: (ev)->
      id = $(ev.currentTarget).data("group-id")
      window.album_router.navigate("group/#{id}", trigger:true)
    goto_item: (ev)->
      id = $(ev.currentTarget).data("item-id")
      window.album_router.navigate("item/#{id}", trigger:true)

    template: _.template_braces($("#templ-album-year").html())
    initialize: ->
      @model = new AlbumYearModel()
      @listenTo(@model,"sync",@render)
    render: ->
      @model.set("list",_.sortBy(@model.get("list"),(x)->x.start_at or x.date).reverse())
      @$el.html(@template(data:@model.toJSON()))
      @$el.appendTo("#album-year")

  AlbumGroupModel = Backbone.Model.extend
    urlRoot: "/api/album/group"

  AlbumGroupView = Backbone.View.extend
    template: _.template_braces($("#templ-album-group").html())
    events:
      "click .gbase.thumbnail":"goto_item"
    goto_item:(ev)->
      id = $(ev.currentTarget).data("item-id")
      window.album_router.navigate("item/#{id}", trigger:true)
    initialize: ->
      @model = new AlbumGroupModel()
      @listenTo(@model,"sync",@render)
    render: ->
      @$el.html(@template(data:@model.toJSON()))
      @$el.appendTo("#album-group")

  AlbumItemModel = Backbone.Model.extend
    urlRoot: "/api/album/item"
  AlbumItemView = Backbone.View.extend
    template: _.template_braces($("#templ-album-item").html())
    initialize: ->
      @model = new AlbumItemModel()
      @listenTo(@model,"sync",@render)
    render: ->
      @$el.html(@template(data:@model.toJSON()))
      @$el.appendTo("#album-item")


  init: ->
    window.album_router = new AlbumRouter()
    Backbone.history.start()
