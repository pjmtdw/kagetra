define (require,exports,module) ->
  WikiRouter = Backbone.Router.extend
    routes:
      "page/:id" : "page"
      "" : "start"
    initialize: ->
      _.bindAll(@,"start")
    page: (id) ->
      window.wiki_item_view?.remove()
      m = new WikiItemModel(id:id)
      window.wiki_item_view = new WikiItemView(model:m)
      m.fetch()
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
      @listenTo(@model,"sync",@render)
    render: ->
      @$el.html(@template(data:@model.toJSON()))
      @$el.appendTo("#wiki-item")
  WikiPanelView = Backbone.View.extend {}
  init: ->
    window.wiki_router = new WikiRouter()
    window.wiki_panel_view = new WikiPanelView()
    Backbone.history.start()


