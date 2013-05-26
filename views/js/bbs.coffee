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
  init: ->
    window.bbs_router = new BbsRouter()
    window.bbs_view = new BbsView(collection: new BbsThreadCollection())
    $("#next-thread").click(-> goto_page(window.bbs_page+1) )
    $("#prev-thread").click(-> goto_page(window.bbs_page-1) )
    Backbone.history.start()
