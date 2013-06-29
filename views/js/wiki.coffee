define (require,exports,module) ->
  class WikiRouter extends _.router_base("wiki",["item","attached_list"])
    routes:
      "page/:id" : "page"
      "" : "start"
    initialize: ->
      _.bindAll(@,"start")
    page: (id) ->
      @remove_all()
      @set_id_fetch("item",WikiItemView,id)
      @set_id_fetch("attached_list",WikiAttachedListView,id)
    start: -> @navigate("page/1", {trigger:true, replace: true})
  WikiItemModel = Backbone.Model.extend
    urlRoot: "/api/wiki/item"
  WikiItemView = Backbone.View.extend
    template: _.template($("#templ-wiki-item").html())
    events:
      "click .link-new" : "link_new"
      "click .link-page" : "link_page"
    link_new: ->
      # TODO
    link_page: (ev)->
      obj = $(ev.currentTarget)
      id = obj.data('link-id')
      window.wiki_router.navigate("/page/#{id}", trigger:true)
    initialize: ->
      @model = new WikiItemModel()
      @listenTo(@model,"sync",@render)
    render: ->
      @$el.html(@template(data:@model.toJSON()))
      @$el.appendTo("#wiki-item")
  WikiPanelView = Backbone.View.extend {}
  WikiAttachedListModel = Backbone.Model.extend
    urlRoot: "/api/wiki/attached_list"
  WikiAttachedListView = Backbone.View.extend
    template: _.template_braces($("#templ-wiki-attached").html())
    events:
      "click .page": "change_page"
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
  init: ->
    window.wiki_router = new WikiRouter()
    window.wiki_panel_view = new WikiPanelView()
    Backbone.history.start()


