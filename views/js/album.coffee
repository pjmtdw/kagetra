define (require,exports,module)->
  class AlbumRouter extends _.router_base("album",["top","year","group","item"])
    routes:
      "year/:year" : "year"
      "group/:id" : "group"
      "item/:id" : "item"
      "" : "start"
    year: (year) -> @remove_all();@set_id_fetch("year",AlbumYearView,year)
    group: (id) -> @remove_all();@set_id_fetch("group",AlbumGroupView,id)
    item: (id) -> @remove_all();@set_id_fetch("item",AlbumItemView,id)
    start: -> @remove_all();@set_id_fetch("top",AlbumTopView)

  AlbumTopModel = Backbone.Model.extend
    url: "/api/album/years"

  AlbumTopView = Backbone.View.extend
    template: _.template_braces($("#templ-album-top").html())
    events:
      "click .gbase.years": "do_list_year"
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
  distance = (p1,p2)->
    dx = p1.x - p2.x
    dy = p1.y - p2.y
    Math.sqrt(dx*dx+dy*dy)
  show_tag = (tag)->
    mk = $("#marker-y")
    tn = $("#tag-name")
    cx = tag.coord_x - mk.width()/2
    cy = tag.coord_y - mk.height()/2
    mk.css("left",cx)
    mk.css("top",cy)
    mk.show()
    tx = tag.coord_x - tn.width()/2
    ty = tag.coord_y + mk.height()/2
    tn.text(tag.name)
    tn.css("left",tx)
    tn.css("top",ty)
    tn.show()
  hide_tag = ->
    mk = $("#marker-y")
    tn = $("#tag-name")
    mk.hide()
    tn.hide()
  AlbumItemView = Backbone.View.extend
    template: _.template_braces($("#templ-album-item").html())
    events:
      "mousemove #photo" : "mouse_moved"
      "click .album-tag" : "album_tag"
    album_tag: (ev)->
      obj = $(ev.currentTarget)
      tag = _.find(@model.get("tags"),(x)->x.id == obj.data("tag-id"))
      show_tag(tag)
    mouse_moved: (ev)->
      ev.stopPropagation()
      x = ev.offsetX
      y = ev.offsetY
      d_min = 999999.0
      tag = null
      for t in @model.get("tags")
        d = distance({x:x,y:y},{x:t.coord_x,y:t.coord_y})
        if d <= t.radius and d < d_min
          tag = t
          d_min = d
      if tag
        show_tag(tag)
      else
        hide_tag()

    initialize: ->
      @model = new AlbumItemModel()
      @listenTo(@model,"sync",@render)
    render: ->
      @$el.html(@template(data:@model.toJSON()))
      @$el.appendTo("#album-item")


  init: ->
    window.album_router = new AlbumRouter()
    Backbone.history.start()
