define ->
  EventCommentCollection = Backbone.Collection.extend
    url: -> "/api/event/comment/list/#{@id}"
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
      @$el.html(@template(data:@collection.toJSON()))
      @comment_num_obj.text("(#{@collection.length})")
      
    refresh: (id, comment_num_obj) ->
      @comment_num_obj = comment_num_obj
      @collection.id = id
      @collection.fetch()
  {
    EventCommentView: EventCommentView
  }
