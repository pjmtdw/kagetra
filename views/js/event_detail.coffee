define ->
  EventItemModel = Backbone.Model.extend
    urlRoot: "/api/event/item"
  EventDetailView = Backbone.View.extend
    template: _.template($("#templ-event-detail").html())
    initialize: ->
      @.listenTo(@model,"sync",@render)
    render: ->
      @$el.html(@template(data:@model.toJSON()))
      @$el.appendTo(@options.target)
    reveal: (model_or_id) ->

  {
    EventItemModel: EventItemModel
    # target: 表示する対象のセレクタ
    # model_or_id: EventItemModel もしくは id
    reveal_detail: (target, model_or_id) ->
      model =  if typeof model_or_id == "number"
                  new EventItemModel(id:model_or_id)
                else
                  model_or_id
      v = new EventDetailView(target:target,model:model)
      _.reveal_view(target,v)
      model.fetch(data:{detail:true})
  }
