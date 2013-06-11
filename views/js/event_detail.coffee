define ->
  EventItemModel = Backbone.Model.extend
    urlRoot: "/api/event/item"
  EventDetailView = Backbone.View.extend
    el: "#container-event-detail"
    template: _.template($("#templ-event-detail").html())
    initialize: ->
      _.bindAll(this,"render")
    render: ->
      @$el.html(@template(data:@model.toJSON()))
    reveal: (model_or_id) ->
      @model =  if typeof model_or_id == "number"
                  new EventItemModel(id:model_or_id)
                else
                  model_or_id
      @$el.foundation("reveal","open")
      @model.fetch(data:{mode:'detail'}).done(@render)
  {
    EventItemModel: EventItemModel
    EventDetailView: EventDetailView
  }
