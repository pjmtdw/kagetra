define ->
  CommentItemView = Backbone.View.extend
    template: _.template($("#templ-comment-item").html())
    events:
      "click .start_edit" : "start_edit"
      "cilck .delete" : "do_delete"
    do_delete: ->
      if confirm("本当に削除してよろしいですか？")
        @model.destory()
    initialize: ->
      @render()
    render: ->
      @$el.html(@template(data:@model.toJSON()))
  
  CommentThreadView = Backbone.View.extend
    template_response: _.template($("#templ-response").html())
    events:
      'click .response-toggle': 'toggle_response'
      'submit .response-form': 'do_response' #absolute
    toggle_response: ->
      container = @$el.find(".response-container")
      @$el.find(".response-toggle").toggleBtnText()

      if container.is(":empty")
        container.html @template_response()
      else
        container.empty()
    response_common: (model)->
      data = @$el.find(".response-form").serializeObj()
      _.save_model_alert(model,data)

  BbsItemModel = Backbone.Model.extend
    urlRoot: "/api/bbs/item"

  # use 'class .. extends ..' only when you have to call super methods
  # since the compiled *.js code will be slightly larger
  class BbsThreadView extends CommentThreadView
    template: _.template_braces($("#templ-bbs-thread").html())
    initialize: ->
      _.bindAll(this,"do_response","toggle_response")
      @render()
    do_response: _.wrap_submit ->
      m = new BbsItemModel(thread_id: @model.get("id"))
      @response_common(m).done(@options.refresh_all)
    render: ->
      title = @model.get("title")
      @$el.html(@template(data:{title: title, public: @model.get("public")}))
      for item in @model.get("items")
        m = new BbsItemModel(item)
        v = new CommentItemView(model: m)
        @$el.find(".comment-body").append(v.$el)

  EventCommentItemModel = Backbone.Model.extend
    urlRoot: '/api/event/comment/item'

  EventCommentCollection = Backbone.Collection.extend
    model: EventCommentItemModel
    url: -> "/api/event/comment/list/#{@id}"
    parse: (data) ->
      @event_name = data.event_name
      data.list

  class EventCommentThreadView extends CommentThreadView
    template: _.template($("#templ-event-comment").html())
    initialize: ->
      _.bindAll(this,"render","refresh")
      @collection = new EventCommentCollection()
      @listenTo(@collection,"sync",@render)
    render: ->
      @$el.html(@template(event_name:@collection.event_name))
      for m in @collection.models
        v = new CommentItemView(model: m)
        @$el.find(".comment-body").append(v.$el)

      @$el.appendTo(@options.target)
      o = @options.comment_num_obj
      if o? then o.text(@collection.length)
    do_response: _.wrap_submit ->
      m = new EventCommentItemModel(event_id:@collection.id)
      that = this
      @response_common(m).done( -> that.collection.fetch() )

    refresh: (id) ->
      @collection.id = id
      @collection.fetch()
  {
    BbsThreadView: BbsThreadView
    # comment_num_obj はコメント追加したときにコメント数を表示するjQueryオブジェクト
    reveal_comment: (target,id,comment_num_obj) ->
      v = new EventCommentThreadView(target:target,comment_num_obj:comment_num_obj)
      _.reveal_view(target,v)
      v.refresh(id)
    # foundation の section にコメント表示
    section_comment: (target,id,comment_num_obj) ->
      v = new EventCommentThreadView(target:target,comment_num_obj:comment_num_obj)
      v.refresh(id)
  }
