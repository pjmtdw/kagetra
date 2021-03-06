define (require,exports,module)->
  const_no_tag = 'タグなし'
  const_no_comment = 'コメントなし'
  $as = require('album_search')
  _.mixin
    show_date: (data)->
      if data.date?
        data.date
      else
        if not data.end_at
          data.start_at
        else
          "#{data.start_at}&sim;#{data.end_at}"
  move_folder_target_select2 = (el,exclude_group_id)->
    el.find(".move-folder-target").select2(
      width:"resolve"
      placeholder: "フォルダ名"
      minimumInputLength: 1
      ajax:
        url: "api/album/search_group"
        type: "POST"
        data: (term,page)->
          q: term
          exclude: exclude_group_id
        results: (data,page) ->
          data
    )

  prompt_tag = (group_id,txt) ->
    select2_opts = {
      ajax:
        url: 'api/album/tag_complete'
        type: "POST"
        data: (term,page)->
          group_id: group_id
          q: term
        results: (data,page) ->
          {results:({text:x} for x in data.results)}
      id: (x)->x.text
      initSelection: (elem,callback) ->
        callback({id:txt,text:txt}) if txt
    }
    _.cb_select2(
      "タグ名",
      {editable:(term)->{id:term,text:term}},
      select2_opts,
      {})
  scroll_to_item = (selector) ->
    selector ||= (id )-> ".album-item[data-id='#{id}']"
    prev = window.album_router.previous()
    if prev and prev.indexOf("item/") == 0
      prev_id = prev.split("/")[1]
      $(selector(prev_id)).scrollHere(-1)
  scroll_to_group = ->
    prev = window.album_router.previous()
    if prev and prev.indexOf("group/") == 0
      prev_id = prev.split("/")[1]
      $(".group[data-group-id='#{prev_id}']").scrollHere(-1)

  class AlbumRouter extends _.router_base("album",["top","year","group","item","search","all_log","stat"])
    routes:
      "year/:year(/:params)" : "year"
      "group/:id" : "group"
      "item/:id" : "item"
      "search/:qs(/:page)" : "search"
      "all_log(/:page)" : "all_log"
      "stat" : "stat"
      "" : "start"
    stat: ->
      @remove_all()
      window.album_stat_view = new AlbumStatView()
    year: (year,params) -> @remove_all();@set_id_fetch("year",AlbumYearView,year,{params:_.deparam(params)})
    group: (id) -> @remove_all();@set_id_fetch("group",AlbumGroupView,id)
    item: (id) ->
      if window.album_search_view
        @come_from = @history[@history.length-1]
        @chunk_list = (x.id for x in window.album_search_view.data.list)
      else if window.album_all_log_view
        @come_from = @history[@history.length-1]
        @chunk_list = (x.id for x in window.album_all_log_view.model.get('list'))
      else if window.album_group_view
        @come_from = @history[@history.length-1]
      else if window.album_year_view or window.album_top_view
        @come_from = null
        @chunk_list = []
      @remove_all()
      @set_id_fetch("item",AlbumItemView,id)
    start: -> @remove_all();@set_id_fetch("top",AlbumTopView)
    all_log: (page)->
      @remove_all()
      window.album_all_log_view = new AlbumAllLogView(page:page)
    search: (qs,page) ->
      if not page
        page = 1
      if not window.album_search_view?
        @remove_all()
        window.album_search_view = new $as.AlbumSearchView(
          init_qs:qs
          do_when_research: (qs,page) ->
            window.album_router.navigate("search/#{encodeURIComponent(qs)}/#{page}", trigger:true)
          do_after_search: ->
            scroll_to_item((id)->"#album-search .gbase[data-id='#{id}']")
        )
      if qs
        window.album_search_view.search(qs,page)

  AlbumTopModel = Backbone.Model.extend
    url: "api/album/years"

  AlbumTopView = Backbone.View.extend
    template: _.template_braces($("#templ-album-top").html())
    events:
      "click .gbase.years": "do_list_year"
      "submit .search-form" : "do_search"
      "click #album-new-upload" : "new_upload"
    new_upload: ->
      target = "#container-album-upload"
      v = new AlbumUploadView(target:target)
      _.reveal_view(target,v)
    do_search: _.wrap_submit (ev) ->
      qs = $(ev.currentTarget).find("input[name='qs']").val()
      window.album_router.navigate("search/#{encodeURIComponent(qs)}", trigger:true)

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
      new AlbumRecentView(data:@model.get('recent'))

  AlbumListViewBase = Backbone.View.extend
    events:
      "click .gbase.group": "goto_group"
      "click .gbase.item": "goto_item"
    goto_group: (ev)->
      id = $(ev.currentTarget).data("group-id")
      window.album_router.navigate("group/#{id}", trigger:true)
    goto_item: (ev)->
      id = $(ev.currentTarget).data("item-id")
      window.album_router.navigate("item/#{id}", trigger:true)
    template: _.template_braces($("#templ-album-list").html())
    render_percent: ->
      $("canvas.percent").each(->
        o = $(@)
        [percent,color] = (o.data(x) for x in ["percent","color"])
        [width,height] = (o.attr(x) for x in ["width","height"])
        barw = Math.max((percent/100.0)*(width-2),1)
        c = o[0].getContext("2d")
        c.strokeStyle = color
        c.fillStyle = "white"
        c.beginPath()
        c.rect(0,0,width,height)
        c.fill()
        c.stroke()
        c.fillStyle = color
        c.strokeStyle = color
        c.fillRect(1,1,barw,height-2)
        true
      )
  AlbumYearModel =  Backbone.Model.extend
    urlRoot: "api/album/year"
  class AlbumYearView extends AlbumListViewBase
    template_menu: _.template_braces($("#templ-album-year-menu").html())
    events:
      _.extend(AlbumListViewBase.prototype.events,
        'click #event-relation-filter .choice' : 'do_relation_filter'
      )
    do_relation_filter: (ev)->
      choice = $(ev.target).closest('[data-choice]').data('choice')
      params = if choice == "both" then "" else "/event_filter=#{choice}"
      window.album_router.navigate("year/#{@model.id}#{params}", trigger:true)

    initialize: ->
      @model = new AlbumYearModel()
      @listenTo(@model,"sync",@render)
    render: ->
      event_filter = @options.params?.event_filter || 'both'
      [show_has_ev,show_no_ev] =
        switch event_filter
          when 'yes'
            [true,false]
          when 'no'
            [false,true]
          else
            [true,true]
      newlist = _.chain(@model.get("list"))
        .filter((x)->
          if _.has(x,"event_id")
            show_has_ev
          else
            show_no_ev
        )
        .sortBy((x)->x.start_at or x.date)
        .value()
        .reverse()

      @model.set("list",newlist)
      @$el.html(@template(data:@model.toJSON()))
      @$el.appendTo("#album-year")
      @$el.find("#album-list").before(@template_menu(event_filter:event_filter))
      @$el.find("#event-relation-filter [data-choice='#{event_filter}']").addClass('active')
      @render_percent()
      scroll_to_item()
      scroll_to_group()
  class AlbumRecentView extends AlbumListViewBase
    initialize: ->
      @render()
    render: ->
      @$el.html(@template(data:@options.data))
      @$el.appendTo("#album-recent")
      @$el.find("#album-list").before($("<div>",text:"新着"))
      @render_percent()

  AlbumEventEditView = Backbone.View.extend
    template: _.template_braces($("#templ-album-event-edit").html())
    events:
      "submit #album-event-edit-form" : 'apply_edit'
    apply_edit: _.wrap_submit ->
      v = @$el.find(".album-event-target").select2("val")
      return if _.isEmpty(v)
      obj = {
        album_group_id: @model.get('id')
        event_id: parseInt(v)
      }
      that = this
      $.ajax("api/album/set_event",{
        data: JSON.stringify(obj),
        contentType: "application/json",
        type: "POST"
      }).done(_.with_error("更新しました", ->
        $(that.options.target).foundation("reveal","close")
      ))
    initialize: ->
      @render()
    render: ->
      @$el.html(@template(data:@model.toJSON()))
      @$el.appendTo(@options.target)
      group_id = @model.get('id')
      @$el.find(".album-event-target").select2(
        width:"resolve"
        placeholder: "大会名"
        minimumInputLength: 0
        ajax:
          url: "api/album/complement_event"
          type: "POST"
          data: (term,page)->
            q: term
            group_id: group_id
          results: (data,page) ->
            data.results.unshift(id:-1,text:"なし")
            data
      )

  AlbumGroupModel = Backbone.Model.extend
    urlRoot: "api/album/group"

  AlbumGroupView = Backbone.View.extend
    template: _.template_braces($("#templ-album-group").html())
    template_info: _.template_braces($("#templ-album-info").html())
    template_info_form: _.template_braces($("#templ-album-info-form").html())
    template_items: _.template_braces($("#templ-album-group-items").html())
    template_tags: _.template_braces($("#templ-album-group-tags").html())
    events:
      "click .owners" : "filter_owners"
      "click .album-tag" : "filter_tag"
      "click #start-edit" : "start_edit"
      "click #add-picture" : "add_picture"
      "click .album-item img" : "thumb_click"
      "click #cancel-edit" : "cancel_edit"
      "click #apply-edit" : "apply_edit"
      "click #album-delete" : "album_delete"
      "click #click-mode .choice" : "click_mode"
      "click #multi-edit" : "multi_edit"
      "click #remove-checked" : "remove_checked"
      "click #reverse-checked" : "reverse_checked"
      "click #event-edit" : "event_edit"
      "click #show-comment" : "show_comment"
      "click #hide-comment" : "hide_comment"
    show_comment: ->
      window.default_show_comment = true
      $("#show-comment").addClass("active")
      $("#hide-comment").removeClass("active")
      @set_param("comment","on")
      @render_items()
    hide_comment: ->
      window.default_show_comment = false
      $("#hide-comment").addClass("active")
      $("#show-comment").removeClass("active")
      @set_param("comment",null)
      @render_items()
    event_edit: ->
      target = "#container-album-event-edit"
      v = new AlbumEventEditView(target:target,model:@model)
      _.reveal_view(target,v)
    get_checked: ->
      @$el.find(".album-item input[type='checkbox']:checked")
    remove_checked: ->
      @get_checked().prop("checked",false)
    reverse_checked: ->
      checked = @get_checked()
      @$el.find(".album-item input[type='checkbox']").prop("checked",true)
      checked.prop("checked",false)
    multi_edit: ->
      checked = @get_checked()
      if checked.length == 0
        _.cb_alert("チェックボックスにチェックを入れて下さい")
        return
      target = "#container-album-multi-edit"
      arr = $.makeArray(checked.map(->$(@).closest(".album-item").data("id")))
      v = new AlbumMultiEditView(target:target,checked:arr,model:@model)
      _.reveal_view(target,v)
    click_mode: (ev)->
      obj = $(ev.currentTarget)
      $("#click-mode .active").removeClass("active")
      obj.addClass("active")
      @click_mode = obj.data("mode")
    add_picture: ->
      target = "#container-album-upload"
      t = _.template_braces($("#templ-album-empty-form").html())
      v = new AlbumUploadView(target:target,is_add_mode:true,tform:t(data:@model.toJSON()))
      _.reveal_view(target,v)
    cancel_edit: ->
      that = this
      @model.fetch().done(-> that.edit_mode = false)
    album_delete: ->
      that = this
      _.cb_prompt("削除するにはdeleteと入れて下さい").done((r)->
        if r == "delete"
          year = that.model.get('year')
          that.model.destroy().done(_.with_error(
            '削除しました',
            ->
              window.album_router.navigate("year/#{year}", trigger:true))))

    apply_edit: ->
      obj = $("#album-item-form").serializeObj()
      obj["item_order"] = $.makeArray($(".album-item").map((i,x)->$(x).data("id")))
      obj["add_rotate"] = @add_rotate
      that = this
      _.save_model(@model,obj,null,true).done(->
        that.model.fetch().done(->
          that.edit_mode = false
          # _.cb_alert("更新完了")
        )
      ).fail((msg)->_.cb_alert("更新失敗: " + msg))
    initialize: ->
      @model = new AlbumGroupModel()
      @listenTo(@model,"sync",@render)
    render: ->
      @generate_extra_tags()
      prev = window.album_router.previous()
      year_params =
        if prev?.indexOf("year/") == 0
          s = prev.split("/")[2]
          if s then "/"+s else  ""
        else
          ""
      @$el.html(@template(data:_.extend(
        @model.toJSON(),{year_params:year_params})))
      @$el.find("#album-info").html(@template_info(data:@model.toJSON()))
      @$el.appendTo("#album-group")
      @render_items()
      @render_tags()
      @apply_uri_filter()
      scroll_to_item()
    generate_extra_tags: ->
      tags = @model.get('tags')
      items = @model.get('items')
      no_tag = (x.id for x in items when x.no_tag)
      no_comment = (x.id for x in items when x.no_comment)
      if not _.isEmpty(no_tag)
        tags.push([const_no_tag,no_tag])
      if not _.isEmpty(no_comment)
        tags.push([const_no_comment,no_comment])

    apply_uri_filter: ->
      [s,t] = Backbone.history.fragment.split('?')
      ts = _.deparam(t)
      owner = ts['owner']
      tag = ts['tag']
      comment = ts['comment']

      if owner
        $(".owners:contains('#{owner}')").click()
      if tag
        $(".album-tag-name:contains('#{tag}')").closest('.album-tag').click()
      if window.default_show_comment or comment
        $("#show-comment").click()

    render_tags: ->
      tags = @model.get('tags')
      if not _.isEmpty(@filter)
        filter = @filter
        tags = _.chain(tags)
          .map(([k,v])->[k,_.intersection(v,filter)])
          .filter(([k,v])->not _.isEmpty(v))
          .sortBy(([k,v])->
            switch k
              when const_no_tag then 0
              when const_no_comment then 1
              else -v.length
          )
          .value()
      $("#album-tags").html(@template_tags(data:{tags:tags}))
    render_items: ->
      items = @model.get('items')
      if @filter
        items = (x for x in items when x.id in @filter)
      window.album_router.chunk_list = (x.id for x in items when not x.hide)
      show_comment = $("#show-comment").hasClass("active")

      $("#album-items").html(@template_items(show_comment:show_comment,data:{items:items}))
    thumb_click: (ev)->
      return unless @edit_mode
      obj = $(ev.currentTarget).closest(".album-item")
      if @click_mode == "move"
        if not @move_from
          @move_from = obj
          obj.addClass("move-from")
        else
          @$el.find(".album-item.move-from").removeClass("move-from")
          _.swap_elem(@move_from,obj)
          @move_from = null
      else
        id = obj.data("id")
        @add_rotate[id] ||= 0
        rot = @add_rotate[id]
        img = obj.find("img")
        img.removeClass("rotate-#{rot}")
        @add_rotate[id] = (rot + 90)%360
        img.addClass("rotate-#{@add_rotate[id]}")
    set_param: (key,value)->
      fragment = Backbone.history.fragment
      [s,t] = fragment.split('?')
      ts = if t then _.deparam(t) else {}
      if _.isNull(value)
        delete ts[key]
      else
        ts[key] = value
      rest = if not _.isEmpty(ts) then "?"+$.param(ts) else ""
      u = s+rest
      return if u == fragment
      window.album_router.navigate(u,trigger:false,replace:true)
      window.album_router.storeRoute()

    remove_owner_filter: ->
      $("#album-info-table .owners").removeClass("selected")
      $("#album-info-table .owners").removeClass("unselected")
      @filter = null
      @set_param('owner',null)

    remove_tag_filter: ->
      @$el.find(".tag-selected").removeClass("tag-selected")
      flag_changed = false
      for x in @model.get("items")
        if x.hide
          x.hide = false
          flag_changed = true
      if flag_changed
        @render_items()
      @set_param('tag',null)
    filter_owners: (ev)->
      return if @edit_mode
      obj = $(ev.currentTarget)
      @remove_tag_filter()
      if obj.hasClass("selected")
        @remove_owner_filter()
      else
        $("#album-info-table .owners").removeClass("selected")
        $("#album-info-table .owners").addClass("unselected")
        obj.removeClass("unselected")
        obj.addClass("selected")
        name = obj.find(".owner-name").text()
        @set_param('owner',name)
        @filter = _.object(@model.get('owners'))[name]
      @render_items()
      @render_tags()
    filter_tag: (ev)->
      return if @edit_mode
      obj = $(ev.currentTarget)
      if obj.hasClass("tag-selected")
        @remove_tag_filter()
      else
        @$el.find(".tag-selected").removeClass("tag-selected")
        obj.addClass("tag-selected")
        tag = obj.find(".album-tag-name").text()
        @set_param('tag',tag)
        visibles = _.object(@model.get("tags"))[tag]
        for x in @model.get("items")
          x.hide = not (x.id in visibles)
        @render_items()
    start_edit: ->
      @remove_owner_filter()
      @remove_tag_filter()
      $("#album-tags").hide()
      $("#album-info").html(@template_info_form(
        is_group: true
        show_comment: true
        data: @model.toJSON()
      ))
      $("#album-items").before($($.parseHTML($("#templ-album-edit-menu").html())))
      $("#album-buttons").hide()
      $("#album-edit-buttons").show()
      @edit_mode = true
      @click_mode = "move"
      $("#album-items a").removeAttr("href")
      $("#album-items .album-item").prepend($("<input>",{type:"checkbox",style:"display:block"}))
      @add_rotate = {}


  AlbumItemModel = Backbone.Model.extend
    urlRoot: "api/album/item"
  distance = (p1,p2)->
    dx = p1.x - p2.x
    dy = p1.y - p2.y
    Math.sqrt(dx*dx+dy*dy)
  show_tag = (tag)->
    mk = $("#marker-y")
    cx = tag.coord_x - mk.width()/2
    cy = tag.coord_y - mk.height()/2
    mk.css("left",cx)
    mk.css("top",cy)
    mk.show()
    tn = $("#tag-name")
    if tag.name
      tn.text(tag.name)
      tx = tag.coord_x - tn.width()/2
      ty = tag.coord_y + mk.height()/2
      tn.css("left",tx)
      tn.css("top",ty)
      tn.show()
    else
      tn.hide()
    $("#album-tags .tag-selected").removeClass("tag-selected")
    $("#album-tags .album-tag[data-tag-id='#{tag.id}']").addClass("tag-selected")
  hide_tag = ->
    mk = $("#marker-y")
    tn = $("#tag-name")
    mk.hide()
    tn.hide()
    $("#album-tags .tag-selected").removeClass("tag-selected")

  AlbumItemView = Backbone.View.extend
    template: _.template_braces($("#templ-album-item").html())
    template_tag: _.template_braces($("#templ-album-tag").html())

    template_info: _.template_braces($("#templ-album-info").html())
    template_info_form: _.template_braces($("#templ-album-info-form").html())

    template_relations: _.template_braces($("#templ-relations").html())

    cross: $("<span>",{html:'&times;',class:"delete-tag cross"})
    editmark: $("<span>",{html:'&sect;',class:"edit-tag"})

    events:
      "mousemove #photo" : (ev) -> if @edit_mode then hide_tag() else @mouse_moved(ev)
      "click #photo" : (ev) -> if @edit_mode then @show_marker(ev);@append_tag(ev) else @mouse_moved(ev) # マウスのないスマホとかのためにもクリックでタグ表示できるようにしておく
      "click .album-tag-name" : (ev) -> obj = $(ev.currentTarget).parent(); if obj.hasClass("tag-selected") then hide_tag() else @album_tag(obj)
      "click .edit-tag" : "edit_tag"
      "mouseover .album-tag" : (ev) -> @album_tag($(ev.currentTarget))
      "click #start-edit" : "start_edit"
      "click #go-random" : "go_random"
      "click #cancel-edit" : "cancel_edit"
      "click .delete-tag" : "delete_tag"
      "click #apply-edit" : "apply_edit"
      "click #scroll-to-relation" : "scroll_to_relation"
      "click #add-relations" : "add_relations"
      "click #album-delete" : "album_delete"
      "click #go-back" : "go_back"
    go_back: ->
      r = window.album_router
      r.navigate(r.come_from,trigger:true)
    go_random: ->
      $.get("/api/album/random").done((data)->
        router = window.album_router
        router.chunk_list = data.group_items
        router.navigate("item/#{data.id}",trigger:true)
      )

    scroll_to_relation: ->
      $("#relation-start").scrollHere(700)

    add_relations: ->
      target = "#container-album-relation"
      that = this
      do_when_click = (ev)->
        id = $(ev.currentTarget).data("id")
        $.get("api/album/thumb_info/#{id}").done((data)->
          $("#relation-start").after($("<div>",{class:"left relation",html:_.album_thumb(data)}))
          that.model.get("relations").push(data)
          _.cb_alert("関連写真に追加しました")
          that.render_relations(true)
        )
      v = new $as.AlbumSearchView(
        target:target
        do_when_click:do_when_click
        top_message:"検索してから写真クリックで関連写真追加できます．"
      )
      _.reveal_view(target,v)

    album_delete: ->
      that = this
      _.cb_prompt("削除するにはdeleteと入れて下さい").done((r)->
        if r == "delete"
          group_id = that.model.get('group').id
          that.model.destroy().done(_.with_error("削除しました",->
            window.album_router.navigate("group/#{group_id}", trigger:true)
          )))

    apply_edit: ->
      obj = $("#album-item-form").serializeObj()
      obj["tag_edit_log"] = @tag_edit_log if not _.isEmpty(@tag_edit_log)
      # 編集途中で写真が回転させられたかもしれないので元のrotateを送る
      obj["orig_rotate"] = @model.get("rotate")
      that = this
      _.save_model(@model,obj,["comment_revision","relations"],true).done(->
        that.model.fetch().done(->
          that.model.unset("tag_edit_log")
          that.model.unset("orig_rotate")
          that.edit_mode = false
          # _.cb_alert("更新完了")
        )
      ).fail((msg)->_.cb_alert("更新失敗: " + msg))
    cancel_edit: ->
      that = this
      task = ->
        that.changed = false
        that.tag_edit_log = {}
        that.model.fetch().done(-> that.edit_mode = false)
      if @changed or not _.isEmpty(@tag_edit_log)
        _.cb_confirm("内容が変更されています．キャンセルして良いですか？").done(task)
      else
        task()

    start_edit: ->
      hide_tag()
      $("#album-info").html(@template_info_form(
        is_group: false
        show_comment: true
        data: @model.toJSON()
      ))
      @$el.find(".album-tag").append(@cross.clone())
      @$el.find(".album-tag").prepend(@editmark.clone())
      $("#album-tags").before($("<div>",html:"<button class='small round' id='add-relations' >関連写真追加</button> 解除するには下の関連写真自体をクリックします．"))
      $("#container").before($("<div>",html:"写真をクリックするとタグを追加できます．タグの&sect;をクリックするとタグ名編集できます．"))
      $("#album-buttons").hide()
      $("#album-edit-buttons").show()
      $(".relation a").removeAttr("href")
      $(".relation a").click(@remove_relation)
      @edit_mode = true
      @new_tag_id = -1
      @tag_edit_log = {}

      that = this
      $("#album-item-form").one("change",":input",->that.changed=true)
      move_folder_target_select2(@$el,null)

    remove_relation: (ev)->
      that = this
      _.cb_confirm("関連写真を解除してもいいですか？").done(->
          id = $(ev.currentTarget).data("id")
          newr = (r for r in that.model.get("relations") when r.id != id)
          that.model.set("relations",newr)
          that.render_relations(true))
    get_pos: (ev)->
      if ev.offsetX? and ev.offsetY?
        [ev.offsetX,ev.offsetY]
      else if ev.pageX? and ev.pageY?
        offset = $(ev.target).offset()
        [ev.pageX-offset.left,ev.pageY-offset.top]
      else
        console.log "cannot determine position"
        [-1,-1]
    append_tag: (ev) ->
      obj = $(ev.currentTarget)
      hide_tag()
      that = this
      prompt_tag(@model.get('group').id).done((data)->
        name = data.text
        o = $($.parseHTML(that.template_tag(tag:{name:name,id:that.new_tag_id})))
        [x,y] = that.get_pos(ev)
        nw = {id:that.new_tag_id,name:name,coord_x:x,coord_y:y,radius:50}
        that.tag_edit_log[that.new_tag_id] = ["update_or_create", nw]
        that.model.get("tags").push(nw)
        o.append(that.cross.clone())
        o.prepend(that.editmark.clone())
        $("#album-tags").append(o)
        that.new_tag_id -= 1
      )

    delete_tag: (ev) ->
      obj = $(ev.currentTarget).parent()
      @tag_edit_log[obj.data("tag-id")] = ["destroy"]
      obj.remove()

    album_tag: (obj)->
      tag_id = obj.data("tag-id")
      tag = _.find(@model.get("tags"),(x)->x.id == tag_id)
      show_tag(tag)
    edit_tag: (ev)->
      obj = $(ev.currentTarget)
      tag_id = obj.parent().data("tag-id")
      tag = _.find(@model.get("tags"),(x)->x.id == tag_id)
      tobj = obj.parent().find(".album-tag-name")
      that = this
      prompt_tag(@model.get('group').id,tobj.text()).done((data)->
        name = data.text
        tag["name"] = name
        that.tag_edit_log[tag_id] = ["update_or_create", tag]
        tobj.text(name))
    show_marker: (ev)->
      ev.stopPropagation()
      [x,y] = @get_pos(ev)
      show_tag({coord_x:x,coord_y:y})
    mouse_moved: (ev)->
      ev.stopPropagation()
      [x,y] = @get_pos(ev)
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
      _.bindAll(@,"remove_relation")
      @model = new AlbumItemModel()
      @listenTo(@model,"sync",@render)
    render_relations: (remove_link)->
      $("#relation-container").html(@template_relations(relations:@model.get("relations")))
      if remove_link
        $(".relation a").removeAttr("href")
        $(".relation a").click(@remove_relation)

    render: ->
      router = window.album_router
      data = @model.toJSON()
      data["go_back"] = router.come_from
      data["group_path"] = "group/#{data.group.id}"
      if router.come_from and router.come_from.indexOf("#{data.group_path}?") == 0
        data["group_path"] = router.come_from

      id = @model.get('id')
      cl = router.chunk_list
      if cl
        idx = cl.indexOf(id)
        if idx >= 0
          data["prev_item"] = cl[idx-1]
          data["next_item"] = cl[idx+1]

      @$el.html(@template(data:data))
      @$el.find("#album-info").html(@template_info(data:@model.toJSON()))
      @$el.appendTo("#album-item")
      @render_relations(false)
      cf = router.come_from
      qs = if cf
            if cf.indexOf("search/") == 0
              decodeURIComponent(cf.split("/")[1])
            else if cf.indexOf("group/") == 0
              [q,r] = cf.split("?")
              _.deparam(r)["tag"]
      if qs
        tags = @model.get('tags')
        if not _.isEmpty(tags)
          tag = _.find(tags,(x)->x.name.indexOf(qs)>=0)
          if tag
            show_tag(tag)



  AlbumUploadView = Backbone.View.extend
    template_form: _.template_braces($("#templ-album-info-form").html())
    template: _.template($("#templ-album-upload").html())
    events:
      "submit #album-item-form" : "do_submit"
    do_submit: ->
      obj = @$el.find("input[type='submit']")
      obj.after($("<div>",id:"now-uploading-message",text:"アップロード中..."))
      obj.hide()
    submit_done: ->
      that = this
      when_success = (res)->
        if that.options.is_add_mode
          # 現在のページをリロード
          Backbone.history.loadUrl( Backbone.history.fragment )
        else
          # なぜか reveal を closed してからしばらく経たないと router.navigate できない
          # TODO: 原因調査
          $(that.options.target).one("closed", ->
            f = -> window.album_router.navigate("group/#{res.group_id}", trigger:true)
            window.setTimeout(f,300))

        $(that.options.target).foundation("reveal","close")
      when_error = ->
        obj = that.$el.find("input[type='submit']")
        obj.show()
        obj.next("#now-uploading-message").remove()
      _.iframe_submit(when_success,when_error)

    initialize: ->
      _.bindAll(@,"submit_done")
      @render()
    render: ->
      tform = @options.tform || @template_form(is_group:true,show_comment:false,data:{})
      @$el.html(tform)
      form = @$el.find("#album-item-form")
      form.attr("method","post")
      form.attr("enctype","multipart/form-data")
      form.attr("action","album/upload")
      form.attr("target","dummy-iframe")
      form.append(@template())
      @$el.appendTo(@options.target)
      $("#dummy-iframe").load(@submit_done)
  AlbumAllLogModel = Backbone.Model.extend
    url: "api/album/all_comment_log"
  AlbumAllLogView = Backbone.View.extend
    template: _.template_braces($("#templ-album-all-log").html())
    initialize: ->
      @model = new AlbumAllLogModel()
      @listenTo(@model,"sync",@render)
      @model.fetch(data:{page:@options.page})
    render: ->
      @$el.html(@template(data:@model.toJSON()))
      @$el.appendTo("#album-all-log")
      scroll_to_item((id)->"#album-all-log .item[data-id='#{id}']")

  AlbumMultiEditView = Backbone.View.extend
    template: _.template_braces($("#templ-album-multi-edit").html())
    events:
      "click .do-move" : "do_move"
      "click .delete-items" : "delete_items"
      "submit .multi-edit-form" : "update_attrs"
    delete_items: ->
      that = this
      _.cb_prompt("削除するにはdeleteと入れて下さい").done((r)->
        if r == "delete"
          checked = that.options.checked
          obj = {item_ids:checked}
          $.ajax("api/album/delete_items/#{that.model.get('id')}",{
            data: JSON.stringify(obj),
            contentType: "application/json",
            type: "DELETE"
          }).done((data)->
            if data.list.length != checked.length
              _.cb_alert("#{data.list.length}枚削除しました．残りは貴方の写真でないため削除できませんでした")
            else
              _.cb_alert("削除しました")
            for c in data.list
              $("#album-items .album-item[data-id='#{c}']").remove()
          ))

    update_attrs: _.wrap_submit (ev)->
      obj = $(ev.currentTarget).serializeObj()
      obj["item_ids"] = @options.checked
      $.ajax("api/album/update_attrs",{
        data: JSON.stringify(obj),
        contentType: "application/json",
        type: "POST"
      }).done(_.with_error("更新しました"))

    do_move: ->
      group_id = @$el.find(".move-folder-target").select2("val")
      return unless group_id
      checked = @options.checked
      obj = {
        group_id: group_id
        item_ids: checked
      }
      $.ajax("api/album/move_group",{
        data: JSON.stringify(obj),
        contentType: "application/json",
        type: "POST"
      }).done(->
        _.cb_alert("移動しました")
        for c in checked
          $("#album-items .album-item[data-id='#{c}']").remove()
      )
    initialize: ->
      @render()
    render: ->
      group_id = @model.get('id')
      @$el.html(@template(data:@model.toJSON(),count:@options.checked.length))
      @$el.appendTo(@options.target)
      move_folder_target_select2(@$el,group_id)
  AlbumStatModel = Backbone.Model.extend
    url: "api/album/stat"
  AlbumStatView = Backbone.View.extend
    template: _.template_braces($("#templ-album-stat").html())
    initialize: ->
      @model = new AlbumStatModel()
      @listenTo(@model,"sync",@render)
      @model.fetch()
    render: ->
      @$el.html(@template(data:@model.toJSON()))
      @$el.appendTo("#album-stat")

  init: ->
    window.album_router = new AlbumRouter()
    Backbone.history.start()
