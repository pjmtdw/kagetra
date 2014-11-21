define (require,exports,module)->
  $co = require("comment")
  _.mixin
    show_all_attrs: (all_attrs,forbidden_attrs) ->
      r = ""
      for [[kid,kname],v] in all_attrs
        g = $('<optgroup>',label:kname)
        for [p,q] in v
          opt = $('<option>',value:p,text:"#{kname}:#{q}")
          if _.contains(forbidden_attrs,p)
            opt.attr("selected","selected")
          g.append(opt)

        r += g[0].outerHTML
      r
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

  additional_data = (id)->
    {
      events:{
        'click .show-event-info':->
          reveal_detail("#container-event-detail",id)
      }
      header_template:"#templ-event-detail-comment-header"
    }

  EventDetailView = Backbone.View.extend
    template: _.template($("#templ-event-detail").html())
    template_p: _.template_braces($("#templ-event-participant").html())
    events:
      "click #contest-info-edit":"info_edit"
      "click .show-comment":"show_comment"
    show_comment: ->
      that = this
      
      $co.reveal_comment("event","#container-event-comment",@model.get('id'),null,additional_data(@model.get('id')))
    info_edit: ->
      show_event_edit(@model)
    initialize: ->
      @listenTo(@model,"sync",@render)
    render: ->
      data = @model.toJSON()
      data["show_comment_button"] = @options.show_comment_button
      @$el.html(@template(data:data))
      @$el.find(".participants").html(@template_p(data:data)) unless @options.no_participant
      @$el.appendTo(@options.target)

  EventEditView = Backbone.View.extend
    template: _.template($("#templ-event-edit").html())
    template_choice: _.template_braces($("#templ-choice-item").html())
    events:
      "click .choice-name" : "edit_choice"
      "click .choice-delete" : "delete_choice"
      "click #add-choice" : "add_choice"
      "change #event-groups" : "group_change"
      "change #cur-group-list" : "copy_info"
      "click #add-contest-group" : "add_contest_group"
    add_contest_group: ->
      _.cb_prompt("追加する恒例大会名:","").done((r)->
        $.post("api/event/group/new",name:r).done((data)->
          $("#event-groups").append($($.parseHTML(_.make_option(data.id,{value:data.id,text:data.name}))))
        ))
      false
    copy_info: ->
      gid = parseInt($("#event-groups").val())
      id = parseInt($("#cur-group-list").val())
      m = new EventItemModel(id:id)
      that = this
      m.fetch(data:{detail:true,edit:true}).done(->
        that.model.set(m.pick(
          "name","formal_name","place","description",
          "forbidden_attrs","hide_choice","official",
          "team_size", "aggregate_attr_id","start_at","end_at"
        ))
        that.model.set("event_group_id",gid)
        ev = new EventEditInfoView(model:that.model)
        ev.render()
        that.$el.find("#event-edit-info").empty()
        that.$el.find("#event-edit-info").append(ev.$el)
        that.group_change(id)
        ev.$el.find("[name='forbidden_attrs']").select2(width:'resolve')
      )
    group_change: (optdef)->
      # 大会の新規作成時のみ有効
      return if @model.get("id") != "contest"
      gid = $("#event-groups").val()
      $.get("api/event/group_list/#{gid}").done((data)->
        opts = "<option>---</option>"
        for d in data
          text = "#{d.date} #{d.name}"
          opts += _.make_option(optdef,{value:d.id,text:text})
        $("#cur-group-list").html(opts)
      )
    edit_choice: (ev) ->
      t = $(ev.currentTarget).text()
      if r = prompt("選択肢名:",t)
        $(ev.currentTarget).text(r)

    add_choice: _.wrap_submit (ev) ->
      if r = prompt("選択肢名:","")
        o = $("<div>",html:@template_choice(x:{positive:true,name:r,id:-1}))
        $("#edit-choice-list").find("[data-positive='false']").first().before(o)

    delete_choice: (ev) ->
      $(ev.currentTarget).parent(".choice-item").remove()
    initialize: ->
      @render()
    render: ->
      @$el.html(@template(data:@model.toJSON()))
      ev = new EventEditInfoView(model:@model)
      ep = new EventEditParticipantView(model:@model)
      @$el.find("#event-edit-info").append(ev.$el)
      @$el.find("#event-edit-participant").append(ep.$el)
      @$el.appendTo(@options.target)
      that = this
      when_done = ->
        that.$el.foundation("section","reflow")

      if not @model.isNew()
        @model.fetch(data:{detail:true,edit:true}).done(when_done)
      else
        ev.render()
        when_done()

  EventParticipantsModel = Backbone.Model.extend
    urlRoot: "api/event/participants"
  EventEditParticipantView = Backbone.View.extend
    template: _.template_braces($("#templ-event-participant").html())
    template_item: _.template($("#templ-participant-item").html())
    template_attr: _.template_braces($("#templ-participant-attr").html())
    cross: $("<span>",{html:'&times;',class:"delete-participant cross"})
    events:
      "click .toggle-edit" : "toggle_edit"
      "click .delete-participant" : "delete_participant"
      "click .add-participant" : "add_participant"
      "click .apply-edit" : "apply_edit"
    apply_edit: ->
      m = new EventParticipantsModel(
        id:@model.get("id")
      )
      that = this
      _.save_model_alert(m,{log:@edit_log},["log"],true).done(->
        that.model.fetch(data:{detail:true,edit:true})
        that.toggle_edit())

    get_choice_attr: (o)->
      attr = o.closest(".event-participants").data("attr-value")
      choice = o.closest(".participant-choice").data("choice-id")
      [attr,choice]
    delete_participant: (ev) ->
      o = $(ev.currentTarget)
      item = o.parent(".item")
      name = item.find(".name").text()
      [attr,choice] = @get_choice_attr(o)
      @edit_log[name]=["delete",attr,choice]
      item.remove()
    add_participant: (ev) ->
      name = prompt("名前","")
      if name
        item = $(ev.currentTarget)
        newi = $($.parseHTML(@template_item(name:name)))
        newi.append(@cross.clone())
        item.before(newi)
        [attr,choice] = @get_choice_attr(item)
        @edit_log[name]=["add",attr,choice]

    toggle_edit: ->
      @edit_log = {}
      @$el.find(".toggle-edit").toggleBtnText()
      @$el.find(".apply-edit").toggle()
      @edit_mode ^= true
      if @edit_mode
        @$el.find(".item").append(@cross.clone())
        that = this
        @$el.find(".participant-choice").each((i,x)->
          obj = _.object(that.model.get("participant_attrs"))
          $(x).find(".event-participants").each((i,y)->
            delete obj[$(y).data("attr-value")]
          )
          for i,v of obj
            $(x).append($($.parseHTML(that.template_attr(data:that.model.toJSON(),templ:that.template_item,q:[i,[]]))))

        )
        @$el.find(".event-participants").append($("<div>",{class:"item add-participant button tiny success",text:"追加"}))
      else
        @$el.find(".delete-participant").remove()
        @$el.find(".add-participant").remove()
    initialize: ->
      @listenTo(@model,"sync",@render)
    render: ->
      data = @model.toJSON()
      data["show_all"] = true
      @$el.html("<button data-toggle-text='キャンセル' class='toggle-edit small round'>編集開始</button> <button class='apply-edit small round hide'>送信</button>"+@template(data:data))

  get_edit_choice_list = ->
    r = []
    $("#edit-choice-list .choice-item").each((index,elem)->
      o = $(elem)
      id = parseInt(o.data("choice-id"))
      positive = o.data("positive")
      name = o.find(".choice-name").text()
      r.push({id:id,positive:positive,name:name})
    )
    r


  EventEditInfoView = Backbone.View.extend
    template: _.template_braces($("#templ-event-edit-info").html())
    events:
      "click #delete-event" : "delete_event"
      "click #move-to-done" : "move_to_done"
      "submit #event-edit-form" : "do_submit"
    move_to_done: ->
      that = this
      _.cb_confirm("この行事を予定表の過去の行事に移動します．よろしいですか？").done(->
        _.save_model_alert(that.model,{done:true},null,true)
      )
      false
    delete_event: ->
      if prompt("削除するにはdeleteと入れて下さい","") == "delete"
        @model.destroy().done(_.with_error("削除しました", -> $("#container-event-edit").foundation("reveal","close")))
      false
    do_submit: ->
      obj = $("#event-edit-form").serializeObj()
      obj["choices"] = get_edit_choice_list()
      m = @model
      if m.get("id") == "contest" || m.get("id") == "party"
        m.unset("id")
      is_new = m.isNew()
      _.save_model_alert(@model,obj,null,true).done(->
        $("#container-event-edit").foundation("reveal","close")
        if is_new and window.event_list_view?
          window.event_list_view.collection.add(m)
        window.event_edit_view.options.do_when_done?(@model)
      )

      false
    initialize: ->
      @listenTo(@model,"sync",@render)
    render: ->
      @$el.html(@template(data:@model.toJSON()))
      @$el.find("[name='forbidden_attrs']").select2(width:'resolve')

  EventGroupModel = Backbone.Model.extend
    urlRoot: "api/result/group"
  EventGroupView = Backbone.View.extend
    template: _.template_braces($("#templ-event-group").html())
    events:
      "click .contest-link" : "do_contest_link"
      "click .page" : "do_page"
      "click #start-edit" : "start_edit"
      "click #cancel-edit" : "cancel_edit"
      "click #apply-edit" : "apply_edit"
    start_edit: ->
      @$el.find(".info").hide()
      @$el.find(".info-edit").show()
      false
    cancel_edit: ->
      @$el.find(".info").show()
      @$el.find(".info-edit").hide()
      false
    apply_edit: _.wrap_submit ->
      obj = $("#event-group-form").serializeObj()
      M = Backbone.Model.extend {urlRoot:'api/event/group'}
      m = new M()
      m.set('id',@model.get('id'))
      that = this
      _.save_model_alert(m,obj,null,true).done(->
        that.model.fetch()
      )
    do_page: (ev)->
      page = $(ev.currentTarget).data("page")
      @model.fetch(data:{page:page})

    do_contest_link: ->
      $("#container-event-group").foundation("reveal","close")
    initialize: ->
      @model = new EventGroupModel(id:@options.id)
      @listenTo(@model,"sync",@render)
      @model.fetch()
    render: ->
      @$el.html(@template(data:@model.toJSON()))
      @$el.appendTo(@options.target)

  show_event_group = (id)->
    t = "#container-event-group"
    v = new EventGroupView(id:id,target:t)
    _.reveal_view(t,v)

  show_event_edit = (model,opts={})->
      t = "#container-event-edit"
      v = new EventEditView(_.extend(opts,{target:t,model:model}))
      _.reveal_view(t,v,true)
      window.event_edit_view = v
  reveal_detail = (target, model_or_id) ->
    model =  if typeof model_or_id == "number"
                new EventItemModel(id:model_or_id)
              else
                model_or_id
    v = new EventDetailView(target:target,model:model,show_comment_button:true)
    _.reveal_view(target,v)
    model.fetch(data:{detail:true})
  {
    show_event_group: show_event_group
    show_event_edit: show_event_edit
    EventItemModel: EventItemModel
    EventDetailView: EventDetailView
    # target: 表示する対象のセレクタ
    # model_or_id: EventItemModel もしくは id
    reveal_detail: reveal_detail
    additional_data: additional_data
  }
