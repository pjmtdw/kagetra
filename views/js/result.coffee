define ->
  CotestResultRouter = Backbone.Router.extend
    routes:
      "contest/:id": "contest"
      "": "contest"
    contest: (id)->
      window.result_view.refresh(id)

  ContestClassModel = Backbone.Model.extend {}

  ContestClassView = Backbone.View.extend
    el: '<div class="columns">'
    template: _.template_braces($('#templ-contest-class').html())
    initialize: ->
      @render()
    render: ->
      @$el.html(@template(
        name:@model.get('name')
        user_results: @model.get('user_results')
      ))
  ContestResultCollection = Backbone.Collection.extend
    url: -> '/api/result/contest/' + (@id or "latest")
    model: ContestClassModel
    parse: (data)->
      @list = data.list
      @name = data.name
      @date = data.date
      @id = data.id
      @group = data.group
      data.event_results
  ContestResultView = Backbone.View.extend
    el: '#contest-result'
    template: _.template_braces($('#templ-contest-result').html())
    events:
      "click .contest-link": "contest_link"
    contest_link: (ev) ->
      id = $(ev.currentTarget).attr('data-id')
      window.result_router.navigate("contest/#{id}",trigger:true)
    initialize: ->
      _.bindAll(this,"refresh","contest_link")
      @collection = new ContestResultCollection()
      @collection.bind("sync",@render,this)
    render: ->
      col = @collection
      @$el.html(@template(
        list:col.list
        group:col.group
        name:col.name
        date:col.date
      ))
      @$el.find("li[data-id='#{col.id}']").addClass("current")
      col.each (m)->
        v = new ContestClassView(model:m)
        $("#contest-result-body").append(v.$el)

      this.$el.foundation('section','reflow')
      window.comment_view.refresh(@collection.id)
    refresh: (id) ->
      @collection.id = id
      @collection.fetch()
  ContestCommentCollection = Backbone.Collection.extend
    url: -> "/api/event/comment/#{@id}"
  ContestCommentView = Backbone.View.extend
    template: _.template($("#templ-contest-comment").html())
    initialize: ->
      _.bindAll(this,"refresh")
      @collection = new ContestCommentCollection()
      @collection.bind("sync",@render,this)
    render: ->
      $("#contest-comment").html(@template(data:@collection.toJSON()))
      $("#contest-comment-count").text("(#{@collection.length})")
    refresh: (id) ->
      @collection.id = id
      @collection.fetch()

  init: ->
    window.result_router = new CotestResultRouter()
    window.result_view = new ContestResultView()
    window.comment_view = new ContestCommentView()
    Backbone.history.start()
