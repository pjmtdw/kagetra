define (require,exports,module) ->
  $co = require("comment")
  BbsRouter = Backbone.Router.extend
    routes:
      "page/:id": "page"
      "": "start"
    initialize: ->
      _.bindAll(this,"start")
    start: ->
      window.bbs_page = 0 # force relading page
      @navigate("page/1", {trigger: true, replace: true})
    page: (page) ->
      page = parseInt(page)
      if window.bbs_page != page
        window.bbs_page = page

        qs = $("#query-string").val()
        data = {page: page}
        data.qs = qs if qs
        window.bbs_view.refresh(data)

  BbsThreadModel = Backbone.Model.extend {}
  BbsThreadCollection = Backbone.Collection.extend
    model: BbsThreadModel
    url: "api/bbs/threads"
  BbsView = Backbone.View.extend
    el: "#bbs-body"
    template_nav: _.template_braces($("#templ-bbs-nav").html())
    initialize: ->
      @collection = new BbsThreadCollection()
      _.bindAll(this,"render")
    refresh: (data) ->
      @collection.reset([])
      @collection.fetch(data:data).done(@render)
    render: ->
      @$el.empty()
      $("#bbs-nav").empty()
      $("#bbs-nav").html(@template_nav(data:@collection.toJSON()))
      for m in @collection.models
        v = new $co.BbsThreadView(model: m,refresh_all:refresh_all)
        @$el.append($("<a name='page/#{window.bbs_page}@#{m.get('id')}'>"))
        d = $("<div>").attr("data-magellan-destination",m.get('id'))
        @$el.append(d)
        @$el.append(v.$el)
      refresh_magellan()

  refresh_magellan = ->
    # since foundation.magellan.js does not support refreshing on dynamic page, we do this dirty hacks.
    # TODO: consider using jquery-waypoints or bootstrap-scrollspy.js
    $(document).foundation("magellan","off") # remove event listener in scope
    # since we canot remove all the event listener using .foundation("magellan","off")
    # we have to remove rest of it by hand.
    $(window).off(".fndtn.magellan")
    $("[data-magellan-expedition]").off(".fndtn.magellan")
    $(document).foundation("magellan",threshold:0,init:false) # force initialize magellan again
    $(document).foundation("magellan","init") # now we can call init

  goto_page = (page) ->
    page = 1 if page < 1
    window.bbs_router.navigate("page/" + page, trigger: true)
    window.scrollTo(0,0)
  refresh_all = ->
    window.bbs_router.navigate("", trigger: true)
  do_search = refresh_all
  create_new_thread = ->
    M = Backbone.Model.extend {
      url: 'api/bbs/thread'
    }
    m = new M()
    obj = $('#new-thread-form').serializeObj()
    _.save_model_alert(m,obj).done( ->
      $("#new-thread-form")[0].reset()
      refresh_thread_new_name()
      $("#new-thread-row").hide()
      $("#new-thread-toggle").toggleBtnText()
      refresh_all()
    )

  refresh_thread_new_name = ->
    c = $("#new-thread-form [name='public']").is(":checked")
    v = if c
          g_user_bbs_public_name ? ( g_user_name ? "" )
        else
          g_user_name ? ""
    $("#new-thread-form [name='user_name']").val(v)
    

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
    $("#search-form").submit(_.wrap_submit(do_search))

    # TODO: use Backbone.View
    ntg = $("#new-thread-toggle")
    ntg.click(->
      row = $("#new-thread-row")
      ntg.toggleBtnText()
      if row.is(":visible")
        row.hide()
      else
        row.show()
    )
    $("#new-thread-form").submit(_.wrap_submit(create_new_thread))
    refresh_thread_new_name()
    $("#new-thread-form [name='public']").click(->
      refresh_thread_new_name()
    )

    Backbone.history.start()
