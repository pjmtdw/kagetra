define ->
  BbsRouter = Backbone.Router.extend
    routes:
      "page/:id": "page"
      "": "start"
    start: ->
      window.bbs_router.navigate("page/1", {trigger: true,replace: true})
    page: (page) ->
      console.log(page)
      window.bbs_page = parseInt(page)
      qs = $("#query-string").val()
      data = {page: page}
      if qs
        data.qs = qs
      window.bbs_view.collection.fetch(data:data).done( ->      
        window.bbs_view.render())
  BbsItemModel = Backbone.Model.extend {}
  BbsItemView = Backbone.View.extend
    template: _.template($("#templ-item").html())
    initialize: ->
      this.render()
    render: ->
      name = this.model.get('name')
      date = this.model.get('date')
      body = this.model.get('body')
      this.$el.html(this.template(name: name, date: date, body: body))
    
  BbsThreadModel = Backbone.Model.extend {}
  BbsThreadCollection = Backbone.Collection.extend
    model: BbsThreadModel
    url: "/api/bbs/threads"
  BbsThreadView = Backbone.View.extend
    template: _.template($("#templ-thread").html())
    template_response: _.template($("#templ-response").html())
    initialize: ->
      this.render()
    render: ->
      title = this.model.get("title")
      items = for item in this.model.get("items")
        m = new BbsThreadModel(item)
        v = new BbsItemView(model: m)
        v.$el.html()
      h = this.template(title: title, items: items)
      this.$el.html(h)
      that = this
      this.$el.find(".response-toggle").click ->
        container = that.$el.find(".response-container")
        do_response = ->
          data = 
            thread_id: that.model.get("thread_id")
            body: container.find(".response-body").val()
          $.post("/api/bbs/response",data).done(refresh_all)
        if container.is(":empty")
          container.html that.template_response()
          container.find(".response-form").submit(_.wrap_submit(do_response))
        else
          container.empty()
  BbsView = Backbone.View.extend
    el: "#bbs-body"
    initialize: ->
      _.bindAll(this,"render")
    render: ->
      e = this.$el
      e.empty()
      this.collection.each (m)->
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
    $.post("/api/bbs/new_thread",data).done(
        $("#new-thread-row").hide()
        refresh_all
        )

  init: ->
    window.bbs_router = new BbsRouter()
    window.bbs_view = new BbsView(collection: new BbsThreadCollection())
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
