define ->
  EventCommentCollection = Backbone.Collection.extend
    url: -> "/api/event/comment/list/#{@id}"
    parse: (data) ->
      @event_name = data.event_name
      data.list
  EventCommentView = Backbone.View.extend
    el: "#event-comment"
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
    initialize: (arg) ->
      _.bindAll(this,"refresh","do_toggle","do_comment")
      @collection = new EventCommentCollection()
      @collection.bind("sync",@render,this)
    render: ->
      @$el.html(@template(event_name:@collection.event_name,data:@collection.toJSON()))
      if @comment_num_obj? then @comment_num_obj.text("(#{@collection.length})")
      
    refresh: (id, comment_num_obj) ->
      @comment_num_obj = comment_num_obj
      @collection.id = id
      @collection.fetch()
    reveal: (id, comment_num_obj) ->
      @$el.foundation("reveal","open")
      @refresh(id, comment_num_obj)
  {
    EventCommentView: EventCommentView
  }
