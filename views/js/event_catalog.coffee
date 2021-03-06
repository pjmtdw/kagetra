define (require,exports,module)->
  ContestResultCollection = Backbone.Collection.extend
    url: 'api/event_catalog/list'
    parse: (data)->
      data.list
  EventCatalogItemView = Backbone.View.extend
    template: _.template_braces($("#templ-event-catalog-item").html())
    render: ->
      @$el.append(@template(data:@model.toJSON()))

  EventCatalogSummaryItemView = Backbone.View.extend
    template: _.template_braces($("#templ-event-catalog-summary-item").html())
    render: ->
      @$el.append(@template(data:@model.toJSON()))

  EventCatalogView = Backbone.View.extend
    el: "#event-catalog"
    initialize: ->
      @collection = new ContestResultCollection()
      @listenTo(@collection,"sync",@render)
      @collection.fetch()
    render: ->
      for m in @collection.models
        v = new EventCatalogItemView(model:m)
        v.render()
        v.$el.appendTo(@el)
        v = new EventCatalogSummaryItemView(model:m)
        v.render()
        $("#event-catalog-summary > tbody").append(v.$el.children())


  init: ->
    window.event_catalog_view = new EventCatalogView()
