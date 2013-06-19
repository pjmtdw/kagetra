define ->
  AlbumRouter = Backbone.Router.extend
    routes:
      "year/:year" : "year"
      "" : "start"
    year: (year) ->
      window.album_view.$el.hide()
      window.album_year_view.model.set("id",year)
      window.album_year_view.model.fetch().done( ->
        window.album_year_view.$el.show()
      )
    start: ->
      window.album_year_view.$el.hide()
      window.album_view.model.fetch().done( ->
        window.album_view.$el.show()
      )


  AlbumYearModel =  Backbone.Model.extend
    urlRoot: "/api/album/year"
  AlbumYearView = Backbone.View.extend
    el: "#album-year"
    template: _.template_braces($("#templ-album-year").html())
    initialize: ->
      _.bindAll(this,"render")
      @model = new AlbumYearModel()
      this.listenTo(@model,"sync",@render)
    render: ->
      @$el.html(@template(data:@model.toJSON()))


  AlbumModel = Backbone.Model.extend
    url: "/api/album/years"
  AlbumView = Backbone.View.extend
    el:"#album"
    template: _.template_braces($("#templ-album").html())
    events:
      "click .group-year": "do_list_year"
    do_list_year: (ev)->
      year = $(ev.currentTarget).attr("data-year")
      window.album_router.navigate("year/#{year}", trigger:true)

    initialize: ->
      _.bindAll(this,"render","do_list_year")
      @model = new AlbumModel()
      this.listenTo(@model,"sync",@render)

    render: ->
      @$el.html(@template(data:@model.toJSON()))
  init: ->
    window.album_router = new AlbumRouter()
    window.album_view = new AlbumView()
    window.album_year_view = new AlbumYearView()
    Backbone.history.start()
