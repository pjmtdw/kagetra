define ->
  CommentItemView = Backbone.View.extend
    template: _.template($("#templ-comment-item").html())
    template_edit: _.template_braces($("#templ-edit-response").html())
    events:
      "click .toggle-edit" : "toggle_edit"
      "click .delete" : "do_delete"
      "submit .response-edit-form" : "do_response"
    do_response: _.wrap_submit ->
      obj = @$el.find(".response-edit-form").serializeObj()
      that = this
      _.save_model_alert(@model,obj)
    do_delete: ->
      if prompt("削除するにはdeleteと入れて下さい") == "delete"
        # TODO: refresh page
        @model.destroy().done(-> alert("削除完了しました"))
    toggle_edit: ->
      if @$el.find(".body").find(".response-edit-form").length == 0
        @$el.find(".toggle-edit").toggleBtnText(false)
        @$el.find(".body").html(@template_edit(data:@model.toJSON()))
      else
        @render()
    initialize: ->
      @listenTo(@model,"sync",@render)
      @render()
    render: ->
      @$el.html(@template(data:@model.toJSON()))
  
  CommentThreadView = Backbone.View.extend
    template_response: _.template_braces($("#templ-response").html())
    events:
      'click .response-toggle': 'toggle_response'
      'submit .response-form': 'do_response' # abstract
    toggle_response: ->
      container = @$el.find(".response-container")
      @$el.find(".response-toggle").toggleBtnText()

      if container.is(":empty")
        dun = if @model and @model.get("public")
                g_user_bbs_public_name ? ( g_user_name ? "" )
              else
                g_user_name ? ""
        container.html @template_response(data:{default_user_name:dun})
      else
        container.empty()
    response_common: (model)->
      data = @$el.find(".response-form").serializeObj()
      _.save_model_alert(model,data)

  BbsItemModel = Backbone.Model.extend
    urlRoot: "api/bbs/item"

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

  class ExtCommentThreadView extends CommentThreadView
    template: _.template_braces($("#templ-ext-comment").html())
    events:
      _.extend(CommentThreadView.prototype.events,
      "click .next-comment-page" : "next_comment_page"
      )
    next_comment_page: (ev)->
      page = $(ev.currentTarget).data("next-page")
      @collection.fetch({data:{page:page}})
    initialize: ->
      _.bindAll(this,"render","refresh")
      mode = @options.mode
      M = Backbone.Model.extend {urlRoot:"api/#{mode}/comment/item"}
      C = Backbone.Collection.extend
        model:M
        url:->"api/#{mode}/comment/list/#{@id}"
        parse: (data)->
          @thread_name = data.thread_name
          @next_page = data.next_page
          data.list
        comparator: (x)-> -Date.parse(x.get("date"))
      @collection = new C()
      @listenTo(@collection,"sync",@render)
    render: ->
      @$el.html(@template(_.pick(@collection,"next_page","thread_name")))
      for m in @collection.models
        v = new CommentItemView(model: m)
        @$el.find(".comment-body").append(v.$el)

      @$el.appendTo(@options.target)
      o = @options.comment_num_obj
      if o? then o.text(@collection.length)
    do_response: _.wrap_submit ->
      m = new @collection.model(thread_id:@collection.id)
      that = this
      @response_common(m).done( -> that.collection.fetch() )

    refresh: (id) ->
      @collection.id = id
      @collection.fetch()
  {
    BbsThreadView: BbsThreadView
    # comment_num_obj はコメント追加したときにコメント数を表示するjQueryオブジェクト
    reveal_comment: (mode,target,id,comment_num_obj) ->
      v = new ExtCommentThreadView(mode:mode,target:target,comment_num_obj:comment_num_obj)
      _.reveal_view(target,v)
      v.refresh(id)
      window["#{mode}_comment_thread_view"] = v
    # foundation の section にコメント表示
    section_comment: (mode,target,id,comment_num_obj) ->
      v = new ExtCommentThreadView(mode:mode,target:target,comment_num_obj:comment_num_obj)
      v.refresh(id)
      window["#{mode}_comment_thread_view"] = v
  }
