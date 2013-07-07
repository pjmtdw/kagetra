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
    tn.text(tag.name)
    tx = tag.coord_x - tn.width()/2
    ty = tag.coord_y + mk.height()/2
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
    template_tag: _.template_braces($("#templ-album-tag").html())
    cross: $("<span>",{html:'&times;',class:"delete-tag cross"})

    events:
      "mousemove #photo" : (ev) -> @mouse_moved(ev) unless @edit_mode
      "click #photo" : (ev) -> if @edit_mode then @append_tag(ev) else @mouse_moved(ev) # マウスのないスマホとかのためにもクリックでタグ表示できるようにしておく
      "click .album-tag-name" : "album_tag"
      "click #start-edit" : "start_edit"
      "click .delete-tag" : "delete_tag"
      "click #apply-edit" : "apply_edit"
    apply_edit: ->
      obj = $("#album-item-form").serializeObj()
      obj["tag_edit_log"] = @tag_edit_log if not _.isEmpty(@tag_edit_log)
      that = this
      _.save_model(@model,obj).done(->
        that.model.fetch().done(->
          that.edit_mode = false
          alert("更新完了")
        )
      ).fail((msg)->alert("更新失敗: " + msg))

    start_edit: ->
      hide_tag()
      if @edit_mode
        that = this
        @model.fetch().done(-> that.edit_mode = false)
        return
      for [s,p] in [
        ["name",""],
        ["place",""],
        ["date","YYYY-MM-DD"]
      ]
        o = $("#album-#{s}")
        c = "<input placeholder='#{p}' type='text' name='#{s}' value='#{_.escape(@model.get(s))}'>"
        o.html(c)
      
      c = "<textarea name='comment' rows='10'>#{_.escape(@model.get('comment'))}</textarea>"
      $("#album-comment").html(c)
      @$el.find(".album-tag").append(@cross.clone())
      $("#canvas").before($("<div>",text:"写真をクリックするとタグを追加できます"))
      $("#start-edit").toggleBtnText()
      obj = $("<button>",text:"更新",class:"small round",id:"apply-edit")
      $("#start-edit").after(obj)
      @edit_mode = true
      @new_tag_id = -1
      @tag_edit_log = {}
    
    append_tag: (ev) ->
      if name = prompt("タグ名")
        o = $($.parseHTML(@template_tag(tag:{name:name,id:@new_tag_id})))
        nw = {id:@new_tag_id,name:name,coord_x:ev.offsetX,coord_y:ev.offsetY,radius:50}
        @tag_edit_log[@new_tag_id] = ["update_or_create", nw]
        @model.get("tags").push(nw)
        o.append(@cross.clone())
        $("#album-tags").append(o)
        @new_tag_id -= 1

    delete_tag: (ev) ->
      obj = $(ev.currentTarget).parent()
      @tag_edit_log[obj.data("tag-id")] = ["destroy"]
      obj.remove()

    album_tag: (ev)->
      obj = $(ev.currentTarget)
      tag_id = obj.parent().data("tag-id")
      tag = _.find(@model.get("tags"),(x)->x.id == tag_id)
      if @edit_mode
        if name = prompt("タグ名",obj.text())
          tag["name"] = name
          @tag_edit_log[tag_id] = ["update_or_create", tag]
          obj.text(name)
      else
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
