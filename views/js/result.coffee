define ->
  CotestResultRouter = Backbone.Router.extend
    routes:
      "contest/:id": "contest"
      "": "contest"
    contest: (id)->
      window.result_view.refresh(id)
  ContestClassModel = Backbone.Model.extend {}
  ContestClassView = Backbone.View.extend {
    el: '<div class="columns">'
    template: _.template_braces($('#templ-contest-class').html())
    initialize: ->
      this.render()
    render: ->
      this.$el.html(this.template(
        name:this.model.get('name')
        user_results: this.model.get('user_results')
      ))
  }
  ContestResultCollection = Backbone.Collection.extend
    url: -> '/api/result/contest/' + (this.id or "latest")
    model: ContestClassModel
    parse: (data)->
      this.list = data.list
      this.name = data.name
      this.date = data.date
      this.id = data.id
      this.group = data.group
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
      this.collection = new ContestResultCollection()
      this.collection.bind("sync",this.render,this)
    render: ->
      col = this.collection
      this.$el.html(this.template(
        list:col.list
        group:col.group
        name:col.name
        date:col.date
      ))
      this.$el.find("li[data-id='#{col.id}']").addClass("current")
      that = this
      col.each (m)->
        v = new ContestClassView(model:m)
        $("#contest-result-body").append(v.$el)

        
    refresh: (id) ->
      this.collection.id = id
      this.collection.fetch()
  init: ->
    window.result_router = new CotestResultRouter()
    window.result_view = new ContestResultView()
    Backbone.history.start()
