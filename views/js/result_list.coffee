define (require,exports,module) ->
  ResultListRouter = Backbone.Router.extend
    routes:
      "year/:year" : "do_year"
      "": -> @navigate("year/#{(new Date()).getFullYear()}",{trigger:true,replace:true})
    do_year: (year) ->
      window.result_list_view?.remove()
      window.result_list_view = new ResultListView(year:year)
  ResultListModel = Backbone.Model.extend
    url: -> "api/result_list/year/#{@get('year')}"
  ResultListView = Backbone.View.extend
    template: _.template_braces($("#templ-result-list").html())
    events:
      "click .page" : "do_page"
    do_page: (ev)->
      year = $(ev.currentTarget).data("year")
      window.result_list_router.navigate("year/#{year}",{trigger:true})
      false
    initialize: ->
      @model = new ResultListModel(year:@options.year)
      @listenTo(@model,"sync",@render)
      @model.fetch()
    render: ->
      @$el.html(@template(data:@model.toJSON()))
      @$el.appendTo("#result-list")
  init: ->
    window.result_list_router = new ResultListRouter()
    Backbone.history.start()
