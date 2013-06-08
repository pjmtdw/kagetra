define ->
  BbsRouter = Backbone.Router.extend
    routes:
      "page/:id": "page"
      "": "start"
    start: ->
      window.bbs_router.navigate("page/1", {trigger: true, replace: true})
    page: (page) ->
      window.bbs_page = parseInt(page)
      qs = $("#query-string").val()
      data = {page: page}
      if qs
        data.qs = qs
      window.bbs_view.refresh(data)

  BbsItemModel = Backbone.Model.extend {}

  BbsItemView = Backbone.View.extend
    template: _.template($("#templ-item").html())
    initialize: ->
      @render()
    render: ->
      name = @model.get('name')
      date = @model.get('date')
      body = @model.get('body')
      @$el.html(@template(name: name, date: date, body: body))

  BbsThreadModel = Backbone.Model.extend {}

  BbsThreadCollection = Backbone.Collection.extend
    model: BbsThreadModel
    url: "/api/bbs/threads"

  BbsThreadView = Backbone.View.extend
    template: _.template($("#templ-thread").html())
    template_response: _.template($("#templ-response").html())
    events:
      'submit .response-form': 'do_response'
      'click .response-toggle': 'toggle_response'
    toggle_response: ->
      container = @$el.find(".response-container")
      if container.is(":empty")
        container.html @template_response()
      else
        container.empty()
    do_response: _.wrap_submit ->
      data =
        thread_id: @model.get("thread_id")
        body: @$el.find(".response-body").val()
      $.post("/api/bbs/response/new",data).done(refresh_all)
    initialize: ->
      _.bindAll(this,"do_response","toggle_response")
      @render()
    render: ->
      title = @model.get("title")
      items = for item in @model.get("items")
        m = new BbsThreadModel(item)
        v = new BbsItemView(model: m)
        v.$el.html()
      h = @template(title: title, items: items)
      @$el.html(h)

  BbsView = Backbone.View.extend
    el: "#bbs-body"
    initialize: ->
      @collection = new BbsThreadCollection()
      _.bindAll(this,"render")
    refresh: (data) ->
      @collection.fetch(data:data).done(@render)
    render: ->
      e = @$el
      e.empty()
      @collection.each (m)->
        v = new BbsThreadView(model: m)
        e.append(v.$el)
  goto_page = (page) ->
    page = 1 if page < 1
    window.bbs_router.navigate("page/" + page, trigger: true)
  refresh_all = ->
    window.bbs_router.navigate("", trigger: true)
  do_search = refresh_all
  create_new_thread = ->
    data =
      title: $("#new-thread-title").val()
      body: $("#new-thread-body").val()
    $.post("/api/bbs/thread/new",data).done(
        $("#new-thread-row").hide()
        refresh_all
        )

  init: ->
    window.bbs_router = new BbsRouter()
    window.bbs_view = new BbsView()
    $("#next-thread").click(-> goto_page(window.bbs_page+1) )
    $("#prev-thread").click(-> goto_page(window.bbs_page-1) )
    $("#search-toggle").click( ->
        row = $("#search-row")
        if row.is(":visible")
          $("#query-string").val("")
          refresh_all()
        row.toggle()
        )
    $("#new-thread-toggle").click( -> $("#new-thread-row").toggle())
    $("#new-thread-form").submit(_.wrap_submit(create_new_thread))
    $("#search-form").submit(_.wrap_submit(do_search))
    Backbone.history.start()
