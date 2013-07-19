define ->
  _.mixin
    show_kind_detail: (data) ->
      s = if data.kind == "contest"
            s1 = if data.official then "公認" else "非公認"
            s2 = _.object(JSON.parse(g_team_sizes_str))[data.team_size]
            s1 + " " + s2
          else
            window.g_event_kinds ||= _.object(JSON.parse(g_event_kinds_str))
            window.g_event_kinds[data.kind]
      if not data.public
        s = "非公開, #{s}"
      s

  EventItemModel = Backbone.Model.extend
    urlRoot: "api/event/item"
  EventDetailView = Backbone.View.extend
    template: _.template($("#templ-event-detail").html())
    template_p: _.template_braces($("#templ-event-participant").html())
    initialize: ->
      @.listenTo(@model,"sync",@render)
    render: ->
      data = @model.toJSON()
      @$el.html(@template(data:data))
      @$el.find(".participants").html(@template_p(data:data))
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
