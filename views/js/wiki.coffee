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
      "page/:id" : "page"
      "" : "start"
    initialize: ->
      _.bindAll(@,"start")
    page: (id) ->
      @remove_all()
      @set_id_fetch("item",WikiItemView,id)
      $("#section-page").click()
      if id != "all" and not _.is_public_mode()
        @set_id_fetch("attached_list",WikiAttachedListView,id)
        @set_id_fetch("log",WikiLogView,id)
        $co.section_comment("wiki","#wiki-comment",id,$("#wiki-comment-count"))
        $(".hide-for-all").show()
      else
        $(".hide-for-all").hide()

    start: -> @navigate("page/all", {trigger:true, replace: true})
  WikiItemModel = Backbone.Model.extend
    urlRoot: "api/wiki/item"
  WikiEditView = Backbone.View.extend
    template: _.template_braces($("#templ-wiki-edit").html())
    events:
      "click #edit-cancel" : "edit_cancel"
      "click #edit-preview" :"edit_preview"
      "click #edit-done" : "edit_done"
      "click #delete-wiki" : "delete_wiki"
    delete_wiki:->
      if prompt("削除するにはdeleteと入れて下さい") == "delete"
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
          that.edit_cancel()

      _.save_model_alert(@model,obj,["revision"]).done(->
        that.model.fetch().done(on_done)
      )
    edit_cancel: ->
      return if @changed and !confirm("内容が変更されています．キャンセルして良いですか？")
      window.wiki_item_view.$el.show()
      window.wiki_edit_view.remove()
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
      @$el.html(@template(data:data))
      @$el.appendTo(@options.target)
  WikiBaseView = Backbone.View.extend
    events:
      "click .link-page" : "link_page"
    edit_common: (m) ->
      window.wiki_item_view.$el.hide()
      window.wiki_edit_view = new WikiEditView(model:m)
    link_page: (ev)->
      obj = $(ev.currentTarget)
      id = obj.data('link-id')
      window.wiki_router.navigate("/page/#{id}", trigger:true)
  
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
      # 最近の閲覧履歴を残しておく
      window.wiki_viewlog = (x for x in window.wiki_viewlog when x[0].toString() not in [id.toString(),"all"])
      window.wiki_viewlog.unshift([id,@model.get("title")])
      window.wiki_viewlog = window.wiki_viewlog[0..3]
      if id != "all" then window.wiki_viewlog.push(["all","全一覧"])

      @$el.html(@template(data:@model.toJSON(),viewlog:window.wiki_viewlog))
      @$el.appendTo("#wiki-panel")

  class WikiItemView extends WikiBaseView
    template: _.template_braces($("#templ-wiki-item").html())
    events: ->
      _.extend(WikiBaseView.prototype.events,
      "click #edit-start" : "edit_start"
      "click .link-new" : "link_new"
      "click .next-page" : "next_page"
      "submit #wiki-edit-form" : -> false
      )
    next_page: (ev)->
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
      @model = new WikiItemModel()
      @listenTo(@model,"sync",@render)
    render: ->
      @$el.html(@template(data:@model.toJSON()))
      @$el.appendTo("#wiki-item")
      window.wiki_panel_view?.remove()
      window.wiki_panel_view = new WikiPanelView(model:@model)
  WikiAttachedListModel = Backbone.Model.extend
    urlRoot: "api/wiki/attached_list"
  WikiAttachedListView = Backbone.View.extend
    template: _.template_braces($("#templ-wiki-attached").html())
    events:
      "click .page": "change_page"
      "click  #toggle-attached" : "toggle_attached"
      "click .delete-attached" : "delete_attached"
    delete_attached: (ev)->
      if prompt("削除するにはdeleteと入れて下さい") == "delete"
        id = $(ev.currentTarget).data("id")
        aj = $.ajax("api/wiki/attached/#{id}",{type: "DELETE"}).done(->alert("削除しました"))

    submit_done: ->
      try
        res = JSON.parse($("#dummy-iframe").contents().find("#response").html())
        if res._error_
          alert(res._error_)
        else if res.result == "OK"
          alert("送信しました")
          @model.fetch()
        else
          alert("エラー")
      catch e
        console.log e.message
        alert("エラー")
    toggle_attached: ->
      $("#toggle-attached").toggleBtnText()
      if $("#attached-form").is(":visible")
        $("#attached-form").hide()
      else
        $("#attached-form").show()
    change_page: (ev)->
      obj = $(ev.currentTarget)
      page = obj.data("page")
      @model.fetch(data:{page:page})
    initialize: ->
      _.bindAll(@,"submit_done")
      @model = new WikiAttachedListModel()
      @listenTo(@model,"sync",@render)
    render: ->
      @$el.html(@template(data:@model.toJSON()))
      @$el.appendTo("#wiki-attached")
      $("#dummy-iframe").load(@submit_done)
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

  init: ->
    window.wiki_router = new WikiRouter()
    # id が 1 のものは Home として特別扱い
    window.wiki_viewlog = []
    if not _.is_public_mode()
      window.wiki_viewlog.push(["1","Home"])
    Backbone.history.start()


