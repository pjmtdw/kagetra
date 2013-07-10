define (require,exports,module)->
  _.mixin
    show_date: (data)->
      if data.date?
        data.date
      else
        if not data.end_at
          data.start_at
        else
          "#{data.start_at}&sim;#{data.end_at}"
  class AlbumRouter extends _.router_base("album",["top","year","group","item","search"])
    routes:
      "year/:year" : "year"
      "group/:id" : "group"
      "item/:id" : "item"
      "search/:qs(/:page)" : "search"
      "" : "start"
    year: (year) -> @remove_all();@set_id_fetch("year",AlbumYearView,year)
    group: (id) -> @remove_all();@set_id_fetch("group",AlbumGroupView,id)
    item: (id) -> @remove_all();@set_id_fetch("item",AlbumItemView,id)
    start: -> @remove_all();@set_id_fetch("top",AlbumTopView)
    search: (qs,page) ->
      qs = decodeURI(qs)
      if not page
        page = 1
      if not window.album_search_view?
        @remove_all()
        window.album_search_view = new AlbumSearchView(init_qs:qs)
      if qs
        window.album_search_view.search(qs,page)

  AlbumTopModel = Backbone.Model.extend
    url: "/api/album/years"

  AlbumTopView = Backbone.View.extend
    template: _.template_braces($("#templ-album-top").html())
    events:
      "click .gbase.years": "do_list_year"
      "submit .search-form" : "do_search"
    do_search: _.wrap_submit (ev) ->
      qs = $(ev.currentTarget).find("input[name='qs']").val()
      window.album_router.navigate("search/#{encodeURI(qs)}", trigger:true)

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
    template_info: _.template_braces($("#templ-album-info").html())
    template_info_form: _.template_braces($("#templ-album-info-form").html())
    template_items: _.template_braces($("#templ-album-group-items").html())
    events:
      "click .album-tag" : "filter_tag"
      "click #start-edit" : "start_edit"
      "click .album-item" : "thumb_click"
      "click #cancel-edit" : "cancel_edit"
      "click #apply-edit" : "apply_edit"
      "click #album-delete" : "album_delete"
    cancel_edit: ->
      that = this
      @model.fetch().done(-> that.edit_mode = false)
    album_delete: ->
      if prompt("削除するにはdeleteと入れて下さい") == "delete"
        year = @model.get('year')
        @model.destroy().done(->
          alert('削除しました')
          window.album_router.navigate("year/#{year}", trigger:true)
        )

    apply_edit: ->
      obj = $("#album-item-form").serializeObj()
      obj["item_order"] = $.makeArray($(".album-item").map((i,x)->$(x).data("id")))
      that = this
      _.save_model(@model,obj).done(->
        that.model.fetch().done(->
          that.edit_mode = false
          # alert("更新完了")
        )
      ).fail((msg)->alert("更新失敗: " + msg))
    initialize: ->
      @model = new AlbumGroupModel()
      @listenTo(@model,"sync",@render)
    render: ->
      @$el.html(@template(data:@model.toJSON()))
      @$el.find("#album-info").html(@template_info(data:@model.toJSON()))
      @$el.appendTo("#album-group")
      @render_items()
    render_items: ->
      $("#album-items").html(@template_items(data:@model.toJSON()))
    thumb_click: (ev)->
      return unless @edit_mode
      obj = $(ev.currentTarget)
      if not @move_from
        @move_from = obj
        obj.addClass("move-from")
      else
        @$el.find(".album-item.move-from").removeClass("move-from")
        tmp = obj.clone()
        obj.replaceWith(@move_from.clone())
        @move_from.replaceWith(tmp)
        @move_from = null
    show_all: ->
      @$el.find(".tag-selected").removeClass("tag-selected")
      for x in @model.get("items")
        x.hide = false
      @render_items()
    filter_tag: (ev)->
      return if @edit_mode
      obj = $(ev.currentTarget)
      if obj.hasClass("tag-selected")
        @show_all()
      else
        @$el.find(".tag-selected").removeClass("tag-selected")
        obj.addClass("tag-selected")
        visibles = _.object(@model.get("tags"))[obj.find(".album-tag-name").text()]
        for x in @model.get("items")
          x.hide = not (x.id in visibles)
        @render_items()
    start_edit: ->
      @show_all()
      $("#album-tags").hide()
      $("#album-info").html(@template_info_form(data:@model.toJSON()))
      $("#album-items").before($("<div>",text:"写真をクリックすると順番を入れ替えることができます"))
      $("#album-buttons").hide()
      $("#album-edit-buttons").show()
      @edit_mode = true
      $("#album-items a").removeAttr("href")


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

    template_info: _.template_braces($("#templ-album-info").html())
    template_info_form: _.template_braces($("#templ-album-info-form").html())

    cross: $("<span>",{html:'&times;',class:"delete-tag cross"})

    events:
      "mousemove #photo" : (ev) -> @mouse_moved(ev) unless @edit_mode
      "click #photo" : (ev) -> if @edit_mode then @append_tag(ev) else @mouse_moved(ev) # マウスのないスマホとかのためにもクリックでタグ表示できるようにしておく
      "click .album-tag-name" : "album_tag"
      "click #start-edit" : "start_edit"
      "click #cancel-edit" : "cancel_edit"
      "click .delete-tag" : "delete_tag"
      "click #apply-edit" : "apply_edit"
      "click #scroll-to-relation" : "scroll_to_relation"
      "click #album-delete" : "album_delete"

    scroll_to_relation: ->
      $("#relation-start").scrollHere(700)

    album_delete: ->
      if prompt("削除するにはdeleteと入れて下さい") == "delete"
        group_id = @model.get('group').id
        @model.destroy().done(->
          alert('削除しました')
          window.album_router.navigate("group/#{group_id}", trigger:true)
        )

    apply_edit: ->
      obj = $("#album-item-form").serializeObj()
      obj["tag_edit_log"] = @tag_edit_log if not _.isEmpty(@tag_edit_log)
      that = this
      _.save_model(@model,obj,["comment_revision"]).done(->
        that.model.fetch().done(->
          that.edit_mode = false
          # alert("更新完了")
        )
      ).fail((msg)->alert("更新失敗: " + msg))
    cancel_edit: ->
      that = this
      @model.fetch().done(-> that.edit_mode = false)

    start_edit: ->
      hide_tag()
      $("#album-info").html(@template_info_form(data:@model.toJSON()))
      @$el.find(".album-tag").append(@cross.clone())
      $("#canvas").before($("<div>",text:"写真をクリックするとタグを追加できます"))
      $("#album-buttons").hide()
      $("#album-edit-buttons").show()
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
      @$el.find("#album-info").html(@template_info(data:@model.toJSON()))
      @$el.appendTo("#album-item")

  AlbumSearchView = Backbone.View.extend
    template: _.template_braces($("#templ-album-search").html())
    template_result: _.template_braces($("#templ-album-search-result").html())
    events:
      "submit .search-form" : "do_submit"
      "click .page" : "goto_page"
    initialize: ->
      @render()
    render: ->
      @$el.html(@template())
      @$el.find(".search-form input[name='qs']").val(@options.init_qs)
      @$el.appendTo("#album-search")
    research: (page)->
      qs = @$el.find(".search-form input[name='qs']").val()
      window.album_router.navigate("search/#{encodeURI(qs)}/#{page}", trigger:true)
    goto_page: (ev)->
      obj = $(ev.currentTarget)
      @research(obj.data("page"))
    do_submit: _.wrap_submit ->
      @research(1)
    search: (qs,page)->
      that = this
      $.post("api/album/search",{qs:qs,page:page}).done((data)->
        that.$el.find(".search-result").html(that.template_result(data:data))
      )

  init: ->
    window.album_router = new AlbumRouter()
    Backbone.history.start()
