define (require,exports,module) ->
  $co = require("comment")
  $atc = require("attached")
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
        @set_id_fetch("attached_list",$atc.AttachedListView,id,{action:"wiki"})
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
      that = this
      _.cb_prompt("削除するにはdeleteと入れて下さい").done((res)->
        if res == "delete"
          that.model.destroy().done(->_.cb_alert("削除しました")))
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
      that = this
      task = ->
        that.changed = false
        window.wiki_edit_view.remove()
        if that.model.isNew()
          # 新規作成の場合は直前に閲覧していたページを表示
          previd = window.wiki_viewlog[0][0]
          that.model.set('id',previd)
          window.wiki_item_view = new WikiItemView(model:that.model)
          that.model.fetch()
        else
          window.wiki_item_view = new WikiItemView(model:that.model)
          window.wiki_item_view.render()
      if @changed
        _.cb_confirm("内容が変更されています．キャンセルして良いですか？").done(task)
      else
        task()

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


