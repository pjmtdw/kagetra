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
  EventCommentCollection = Backbone.Collection.extend
    url: -> "/api/event/comment/list/#{@id}"
    parse: (data) ->
      @event_name = data.event_name
      data.list
  EventCommentView = Backbone.View.extend
    template: _.template($("#templ-event-comment").html())
    events:
      "click .toggle-comment": "do_toggle"
      "submit .comment-form": "do_comment"
    do_comment: ->
      data = @$el.find(".comment-form").serializeObj()
      data.event_id = @collection.id
      that = this
      $.post('/api/event/comment/item',data).done( ->
        that.collection.fetch()
      )
      false
    do_toggle: ->
      @$el.find(".comment-form").toggle()
      @$el.find(".toggle-comment").toggleBtnText()
    initialize: ->
      _.bindAll(this,"render","refresh")
      @collection = new EventCommentCollection()
      this.listenTo(@collection,"sync",@render)
    render: ->
      @$el.html(@template(event_name:@collection.event_name,data:@collection.toJSON()))
      @$el.appendTo(@options.target)
      o = @options.comment_num_obj
      if o? then o.text(@collection.length)
      
    refresh: (id) ->
      @collection.id = id
      @collection.fetch()
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
      model.fetch(data:{mode:'detail'})

    # comment_num_obj はコメント追加したときにコメント数を表示するオブジェクト
    reveal_comment: (target,id,comment_num_obj) ->
      v = new EventCommentView(target:target,comment_num_obj:comment_num_obj)
      _.reveal_view(target,v)
      v.refresh(id)
    # foundation の section にコメント表示
    section_comment: (target,id,comment_num_obj) ->
      v = new EventCommentView(target:target,comment_num_obj:comment_num_obj)
      # 親 section が reflow されてるため el を設定し直す必要がある
      v.setElement($(target).get(0))
      v.refresh(id)
  }
