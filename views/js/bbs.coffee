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
      window.bbs_view.collection.fetch(data:{page: page}).done( ->      
        window.bbs_view.render())
  BbsThreadModel = Backbone.Model.extend {}
  BbsThreadCollection = Backbone.Collection.extend
    model: BbsThreadModel
    url: "/api/bbs/threads"
  BbsThreadView = Backbone.View.extend
    render: ->
      this.$el.append(this.model.get("title"))
  BbsView = Backbone.View.extend
    el: "#bbs-body"
    initialize: ->
      _.bindAll(this,"render")
    render: ->
      e = this.$el
      e.empty()
      this.collection.each (m)->
        e.append((new BbsThreadView(model: m)).render())
  goto_page = (page) ->
    page = 1 if page < 1
    window.bbs_router.navigate("page/" + page, trigger: true)
  init: ->
    window.bbs_router = new BbsRouter()
    window.bbs_view = new BbsView(collection: new BbsThreadCollection())
    $("#next-thread").click(-> goto_page(window.bbs_page+1) )
    $("#prev-thread").click(-> goto_page(window.bbs_page-1) )
    Backbone.history.start()
