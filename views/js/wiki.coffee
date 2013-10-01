define (require,exports,module) ->
  $co = require("comment")
  _.mixin
    show_size: (x) ->
      if x < 1024
        "#{x} bytes"
      else if x < 1048576
        "#{Math.floor(x/1024)} KB"
      else
        "#{Math.floor(x/1048576)} MB"
  class WikiRouter extends _.router_base("wiki",["item","attached_list","edit","comment","comment_thread","log"])
    routes:
      "page/:id(/:extra)" : "page"
      "" : "start"
    initialize: ->
      _.bindAll(@,"start")
    page: (id,extra) ->
      @remove_all()
      @set_id_fetch("item",WikiItemView,id)
      if extra
        $("#section-#{extra}").click()
      else
        $("#section-page").click()
      if id != "all" and not g_public_mode
        $(".hide-for-all").show()
        @set_id_fetch("attached_list",WikiAttachedListView,id)
        @set_id_fetch("log",WikiLogView,id)
        $co.section_comment("wiki","#wiki-comment",id,$("#wiki-comment-count"))
      else
        $(".hide-for-all").hide()

    start: ->
      if g_public_mode
        @navigate("page/all", {trigger:true, replace: true})
      else
        @navigate("page/1", {trigger:true, replace: true})

  WikiItemModel = Backbone.Model.extend
    urlRoot: "api/wiki/item"
  WikiEditView = Backbone.View.extend
    template: _.template_braces($("#templ-wiki-edit").html())
    events:
      "click #edit-cancel" : "edit_cancel"
      "click #edit-preview" :"edit_preview"
      "click #edit-done" : "edit_done"
      "submit #wiki-edit-form" : "edit_done"
      "click #delete-wiki" : "delete_wiki"
    delete_wiki:->
      if prompt("削除するにはdeleteと入れて下さい","") == "delete"
        @model.destroy().done(->alert("削除しました"))
    edit_done:->
      obj = $("#wiki-edit-form").serializeObj()
      is_new = @model.isNew()
      that = this
      on_done = ->
        if is_new
          window.wiki_edit_view.remove()
          window.wiki_router.navigate("page/#{that.model.get('id')}", {trigger:true})
        else
          that.changed = false
          that.edit_cancel()

      _.save_model_alert(@model,obj,["revision"],true).done(->
        that.model.fetch().done(on_done)
      )
      false
    edit_cancel: ->
      return if @changed and !confirm("内容が変更されています．キャンセルして良いですか？")
      @changed = false
      window.wiki_edit_view.remove()
      if @model.isNew()
        # 新規作成の場合は直前に閲覧していたページを表示
        previd = window.wiki_viewlog[0][0]
        @model.set('id',previd)
        window.wiki_item_view = new WikiItemView(model:@model)
        @model.fetch()
      else
        window.wiki_item_view = new WikiItemView(model:@model)
        window.wiki_item_view.render()

    edit_preview: ->
      target = "#container-wiki-preview"
      v = new WikiPreviewView(target:target)
      _.reveal_view(target,v)
    initialize: ->
      @listenTo(@model,"sync",@render)
      if @model.isNew()
        @render()
    render: ->
      @$el.html(@template(data:@model.toJSON()))
      @$el.appendTo("#wiki-edit")
      that = this
      $("#wiki-edit-form").one("change",":input",->that.changed=true)
  WikiPreviewView = Backbone.View.extend
    template: _.template($("#templ-wiki-preview").html())
    initialize: ->
      body = $("#wiki-edit-form [name='body']").val()
      that = this
      $.post("api/wiki/preview",{body:body}).done((data)->that.render(data))
    render: (data)->
      try
        @$el.html(@template(data:data))
        @$el.appendTo(@options.target)
        @$el.find("a").attr("target","_blank")
      catch e
        console.log "Error: " + e.message
  WikiBaseView = Backbone.View.extend
    events:
      "click .link-page" : "link_page"
    edit_common: (m) ->
      window.wiki_edit_view = new WikiEditView(model:m)
      window.wiki_item_view.remove()
      $("#edit-new").hide()

    link_page: (ev)->
      obj = $(ev.currentTarget)
      id = obj.data('link-id')
      extra = obj.data('link-extra') || ''
      window.wiki_router.navigate("/page/#{id}#{extra}", trigger:true)

  class WikiPanelView extends WikiBaseView
    template: _.template_braces($("#templ-wiki-panel").html())
    events: ->
      _.extend(WikiBaseView.prototype.events,
      "click #edit-new" : "edit_new"
      )
    initialize: ->
      @render()
    edit_new: ->
      @edit_common(new WikiItemModel())
    render: ->
      id = @model.get("id")
      if id
        # 最近の閲覧履歴を残しておく
        window.wiki_viewlog = (x for x in window.wiki_viewlog when x[0].toString() not in [id.toString(),"all"])
        window.wiki_viewlog.unshift([id,@model.get("title")])
        window.wiki_viewlog = window.wiki_viewlog[0..4]
        if id != "all" then window.wiki_viewlog.push(["all","全一覧"])
      @$el.html(@template(data:@model.toJSON(),viewlog:window.wiki_viewlog.slice().reverse()))
      @$el.appendTo("#wiki-panel")

  class WikiItemView extends WikiBaseView
    template: _.template_braces($("#templ-wiki-item").html())
    events: ->
      _.extend(WikiBaseView.prototype.events,
      "click #edit-start" : "edit_start"
      "click .link-new" : "link_new"
      "click .goto-page" : "goto_page"
      "submit #wiki-edit-form" : -> false
      )
    goto_page: (ev)->
      obj = $(ev.currentTarget)
      page = obj.data("page-num")
      @model.fetch(data:{page:page})
    edit_start: ->
      @edit_common(@model)
      @model.fetch(data:{edit:true})
    link_new: (ev) ->
      obj = $(ev.currentTarget)
      title = obj.data('link-new')
      @edit_common(new WikiItemModel(title:title))
    initialize: ->
      @model ||= new WikiItemModel()
      @listenTo(@model,"sync",@render)
    render: ->
      try
        @$el.html(@template(data:@model.toJSON()))
        @$el.appendTo("#wiki-item")
        $("#wiki-attached-count").text("( #{@model.get('attached_count')||0} )")
        $("#wiki-container").sectionTitleExpandHorizontal("#wiki-attached-count")
      catch e
        console.log "Error: " + e.message

      window.wiki_panel_view?.remove()
      window.wiki_panel_view = new WikiPanelView(model:@model)
  WikiAttachedUploadView = Backbone.View.extend
    template: _.template_braces($("#templ-wiki-attached-upload").html())
    events:
      "click .delete-attached" : 'delete_attached'
    delete_attached: _.wrap_submit ->
      if prompt("削除するにはdeleteと入れて下さい","") == "delete"
        that = this
        aj = $.ajax("api/wiki/attached/#{@options.data.id}",{type: "DELETE"}).done(->
          alert("削除しました")
          that.options.when_success()
        )
    initialize: ->
      _.bindAll(@,"submit_done")
      @render()
    render: ->
      @$el.html(@template(data:@options.data))
      @$el.appendTo(@options.target)
      $("#dummy-iframe").load(@submit_done)
    submit_done: ->
      that = this
      _.iframe_submit(@options.when_success)

  WikiAttachedListModel = Backbone.Model.extend
    urlRoot: "api/wiki/attached_list"
  WikiAttachedListView = Backbone.View.extend
    template: _.template_braces($("#templ-wiki-attached").html())
    events:
      "click .page": "change_page"
      "click  #show-attached-upload" : "show_attached_upload"
      "click .edit-attached" : "edit_attached"
    reveal_it: (data)->
      target = "#container-attached-upload"
      that = this
      when_success = ->
        that.model.fetch()
        $(target).foundation("reveal","close")
      v = new WikiAttachedUploadView(target:target,data:data,when_success:when_success)
      _.reveal_view(target,v)
    edit_attached: (ev)->
      attached_id = $(ev.currentTarget).data("id")
      @reveal_it(_.extend(@model.pick('item_id'),_.find(@model.get('list'),(x)->x.id==attached_id)))

    show_attached_upload: ->
      @reveal_it(@model.pick('item_id'))
    change_page: (ev)->
      obj = $(ev.currentTarget)
      page = obj.data("page")
      @model.fetch(data:{page:page})
    initialize: ->
      @model = new WikiAttachedListModel()
      @listenTo(@model,"sync",@render)
    render: ->
      @$el.html(@template(data:@model.toJSON()))
      @$el.appendTo("#wiki-attached")
  WikiLogModel = Backbone.Model.extend
    urlRoot: "api/wiki/log"
  WikiLogView = Backbone.View.extend
    template: _.template_braces($("#templ-wiki-log").html())
    events:
      "click #wiki-log-next-page" : "next_page"
    next_page: (ev)->
      page = $(ev.currentTarget).data("page")
      @model.fetch(data:{page:page})
      false

    initialize: ->
      @model = new WikiLogModel()
      @listenTo(@model,"sync",@render)
    render: ->
      @$el.html(@template(data:@model.toJSON()))
      @$el.appendTo("#wiki-log")

  switch_uri = (ev)->
    [page,id] = Backbone.history.fragment.split('/')
    tab = $(ev.currentTarget).attr("id")
    rest = if tab == "section-page" then "" else tab.replace(/^section-/,"/")
    window.wiki_router.navigate("#{page}/#{id}#{rest}",trigger:false,replace:true)
  init: ->
    window.wiki_router = new WikiRouter()
    window.wiki_viewlog = []
    $("section.hide-for-public").hide() if g_public_mode
    $("#wiki-container a").on("click",switch_uri)
    Backbone.history.start()


