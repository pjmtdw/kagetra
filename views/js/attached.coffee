define ->
  AttachedUploadView = Backbone.View.extend
    template: _.template_braces($("#templ-attached-upload").html())
    events:
      "click .delete-attached" : 'delete_attached'
    delete_attached: _.wrap_submit ->
      that = this
      _.cb_prompt("削除するにはdeleteと入れて下さい").done((res)->
        if res == "delete"
          $.ajax("api/#{that.options.action}/attached/#{that.options.data.id}",{type: "DELETE"}).done(
            ->_.cb_alert("削除しました").always(that.options.when_success)))
    initialize: ->
      _.bindAll(@,"submit_done")
      @render()
    render: ->
      @$el.html(@template(data:@options.data,action:@options.action))
      # <form target='dummy-iframe' .. > を指定しているので送信が完了すると #dummy-frame に load イベントが発生する
      @$el.find("#dummy-iframe").load(@submit_done)
      @$el.appendTo(@options.target)
    submit_done: ->
      _.iframe_submit(@options.when_success)
  AttachedListModel = Backbone.Model.extend
    initialize: (attrs, opts) ->
      @options = _.clone(opts)
    urlRoot: -> "api/#{@options.action}/attached_list"
  AttachedListView = Backbone.View.extend
    template: _.template_braces($("#templ-attached").html())
    events:
      "click .page": "change_page"
      "click  #show-attached-upload" : "show_attached_upload"
      "click .edit-attached" : "edit_attached"
    reveal_it: (data)->
      target = "#container-attached-upload"
      that = this
      when_success = ->
        that.model.fetch()
        $.colorbox.close()
      v = new AttachedUploadView(target:target,data:data,action:@options.action,when_success:when_success)
      $.colorbox(
        html: v.$el
        transition: "none"
        fadeOut: 100
        width: 720
        opacity: 0.5
      )
    edit_attached: (ev)->
      attached_id = $(ev.currentTarget).data("id")
      @reveal_it(_.extend(@model.pick('item_id'),_.find(@model.get('list'),(x)->x.id==attached_id)))

    show_attached_upload: ->
      @reveal_it(@model.pick('item_id'))
    change_page: (ev)->
      obj = $(ev.currentTarget)
      page = obj.data("page")
      @model.fetch(data:{page:page})
    initialize: ->
      @model = new AttachedListModel({},_.pick(@options,'action'))
      @listenTo(@model,"sync",@render)
    render: ->
      @$el.html(@template(data:@model.toJSON(),action:@options.action))
      @$el.appendTo("##{@options.action}-attached")
  {
    AttachedListView: AttachedListView
  }
