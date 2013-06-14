define (require,exports,module) ->
  # Requirng schedule_item in multiple scripts cause minified file larger
  # since both scripts contains whole content of schedule_item.js.
  # TODO: do not require schedule_item here and load it dynamically.
  $ed = require("event_detail")
  
  CotestResultRouter = Backbone.Router.extend
    routes:
      "contest/:id": "contest"
      "": "contest"
    contest: (id)->
      window.result_view.refresh(id)

  ContestChunkModel = Backbone.Model.extend {}

  ContestChunkView = Backbone.View.extend
    el: '<div class="columns">'
    template: _.template_braces($('#templ-contest-chunk').html())
    initialize: ->
      @render()
    render: ->
      @$el.html(@template(data:@model.toJSON()))
  ContestResultCollection = Backbone.Collection.extend
    url: -> '/api/result/contest/' + (@id or "latest")
    model: ContestChunkModel
    parse: (data)->
      @recent_list = data.recent_list
      @name = data.name
      @date = data.date
      @id = data.id
      @contest_classes = data.contest_classes
      @group = data.group
      data.contest_results
  # TODO: split this view to ContestInfoView which has name, date, group, list  and ContestResultView which only has result
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
        recent_list:col.recent_list
        group:col.group
        name:col.name
        date:col.date
      ))
      @$el.find("li[data-id='#{col.id}']").addClass("current")
      cur_class = null
      col.each (m)->
        if m.get("class_id") != cur_class
          cur_class = m.get("class_id")
          class_name = col.contest_classes[cur_class]
          $("#contest-result-body").append($("<div>",{class:"columns class-name",text:class_name}))
        v = new ContestChunkView(model:m)
        $("#contest-result-body").append(v.$el)

      this.$el.foundation('section','reflow')
      cv = window.comment_view
      # since comment_view is reflowed, we have to reset element
      cv.setElement($("#event-comment").get(0))
      cv.refresh(@collection.id, $("#event-comment-count"))
    refresh: (id) ->
      @collection.id = id
      @collection.fetch()

  init: ->
    window.result_router = new CotestResultRouter()
    window.result_view = new ContestResultView()
    window.comment_view = new $ed.EventCommentView()
    Backbone.history.start()
