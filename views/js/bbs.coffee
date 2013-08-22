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

  BbsItemModel = Backbone.Model.extend
    urlRoot: "api/bbs/item"

  magellan_offset = (delta)->
    delta = if delta? then delta else 8 # ちょっと多めの余白
    mage = $("[data-magellan-expedition]")
    height = mage.outerHeight()
    offset =  if mage.css("position") == "fixed"
              # 既に magellan が画面の一番上にfixedされている状態
                height
              else
              # スクロールの途中で magellan がfixedされるのでその分を考慮
                height*2
    -offset-delta

  # use 'class .. extends ..' only when you have to call super methods
  # since the compiled *.js code will be slightly larger
  class BbsThreadView extends $co.CommentThreadView
    template: _.template_braces($("#templ-bbs-thread").html())
    events:
      _.extend($co.CommentThreadView.prototype.events,
      "click .goto-new" : "goto_new"
      "click .goto-bottom" : "goto_bottom"
      )
    goto_bottom: ->
      @$el.find(".response-toggle").first().scrollHere(500,magellan_offset())
    goto_new: ->
      @$el.find(".is-new").first().scrollHere(500,magellan_offset())
    initialize: ->
      _.bindAll(this,"do_response","toggle_response")
      @render()
    do_response: _.wrap_submit ->
      m = new BbsItemModel(thread_id: @model.get("id"))
      @response_common(m).done(@options.refresh_all)
    render: ->
      @$el.html(@template(data:@model.pick("title","public","has_new_comment")))
      for item in @model.get("items")
        m = new BbsItemModel(item)
        v = new $co.CommentItemView(model: m)
        @$el.find(".comment-body").append(v.$el)

  BbsThreadModel = Backbone.Model.extend
    url: 'api/bbs/thread'
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
      $("#bbs-nav .goto-thread").on("click",(ev)->
        id = $(ev.currentTarget).data("id")
        $("[data-magellan-destination='#{id}']").scrollHere(-1,magellan_offset(-3))
        false
      )
      for m in @collection.models
        v = new BbsThreadView(model: m,refresh_all:refresh_all)
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
    m = new BbsThreadModel()
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

    $("#new-thread-form .hide-for-public").hide() if g_public_mode
    Backbone.history.start()
