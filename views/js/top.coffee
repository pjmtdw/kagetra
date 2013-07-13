define (require,exports,module) ->
  $ed = require("event_detail")
  $si = require("schedule_item")
  $co = require("comment")
  $ch = require("chosen")
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
    show_new_comment: (count,has_new)->
      c = if has_new
        " <span class='new-comment'>new</span>"
      else
        ""
      "( <span class='comment-count'>#{count}</span>#{c} )"
    show_kind_symbol: (kind,official) ->
      s = switch kind
            when "contest"
              if official then "spades" else "clubs"
            when "party"
              "hearts"
            else
              "diams"
      "<span class='event-symbol #{s}'>&#{s};</span>"
    show_date: (s) ->
      return "なし" unless s
      today = new Date()
      [y,m,d] = (parseInt(x) for x in s.split('-'))
      date = new Date(y,m-1,d)
      sa = "<span class='event-date'>"
      sb = "</span>"
      sw = "<span class='event-weekday'>"
      wday = _.weekday_ja()[date.getDay()]

      ymd = "#{sa}#{m}#{sb} 月 #{sa}#{d}#{sb} 日 (#{sw}#{wday}#{sb})"
      if today.getFullYear() != y
        ymd = "#{sa}#{y}#{sb} 年 " + ymd
      ymd
  show_deadline = (deadline_day) ->
    if not deadline_day?
      "なし"
    else if deadline_day < 0
      "<span class='deadline-expired'>過ぎました</span>"
    else if deadline_day == 0
      "<span class='deadline-today'>今日</span>"
    else if deadline_day == 1
      "<span class='deadline-tomorrow'>明日</span>"
    else
      "あと <span class='deadline-future'>#{deadline_day}</span> 日"

  SchedulePanelCollection = Backbone.Collection.extend
    model: $si.ScheduleModel
    url: "api/schedule/panel"

  SchedulePanelView = Backbone.View.extend
    el: '#schedule-panel'
    initialize: ->
      _.bindAll(this,"render")
      @collection = new SchedulePanelCollection()
      @collection.fetch().done(@render)
    render: ->
      @subviews = {}
      for m in @collection.models
        v = new $si.ScheduleItemView(model:m)
        v.render()
        @$el.append(v.$el)
        [y,m,d] = (m.get(x) for x in ["year","mon","day"])
        @subviews["#{y}-#{m}-#{d}"] = v

  EventListCollection = Backbone.Collection.extend
    model: $ed.EventItemModel
    url: "api/event/list"
    set_comparator: (attr) ->
      @order = attr
      sign = if attr in ["created_at","latest_comment_date","participant_count"] then -1 else 1
      ETERNAL_FUTURE = "9999-12-31_"
      ETERNAL_PAST = "0000-01-01_"
      f = if attr in ["created_at","date","latest_comment_date"]
            PREFIX = if sign == -1 then ETERNAL_PAST else ETERNAL_FUTURE
            (x)-> x.get(attr) || (PREFIX + x.get("name"))
          else if attr == "deadline_day"
            (x)->
              dd = x.get("deadline_day")
              if not dd?
                999999999
              else if dd < 0
                999999 - dd
              else
                dd
      @comparator = (x,y) -> fx=f(x);fy=f(y);if fx>fy then sign else if fx<fy then -sign else 0
  show_event_edit = (model)->
      t = "#container-event-edit"
      v = new EventEditView(target:t,model:model)
      _.reveal_view(t,v)
  EventItemBaseView = Backbone.View.extend
    events:
      "click .show-detail": "show_detail"
      "click .show-comment": "show_comment"
    initialize: ->
      @listenTo(@model,"sync",@render)
    show_detail: ->
      $ed.reveal_detail("#container-event-detail",@model)
    show_comment: ->
      $co.reveal_comment("event","#container-event-comment",@model.get('id'),@$el.find(".comment-count"))
    render: ->
      json = @model.toJSON()
      json.deadline_str = show_deadline(json.deadline_day)
      @$el.html(@template(data:json))
      if not json.forbidden
        cm =
          if @options.choice_model
            @options.choice_model
          else
            new EventChoiceModel(choices:json.choices,id:json.choice)
        cv = new EventChoiceView(model:cm,event_name:json.name,parent:this)
        cv.render()
        @$el.find(".event-choice").append(cv.$el)
      else
        @$el.find(".event-choice").append($("<span>",class:"forbidden",text:"貴方は登録不可です"))
      
      @choice_model = cm

  EventItemView = EventItemBaseView.extend
    el: '<li>'
    template: _.template_braces($('#templ-event-item').html())
    events: ->
      _.extend(EventItemBaseView.prototype.events,
      "click .show-edit": -> show_event_edit(@model)
      )

  EventAbbrevView = EventItemBaseView.extend
    template: _.template($('#templ-event-abbrev').html())

  EventListView = Backbone.View.extend
    el: '#event-list'
    template: _.template($('#templ-event-list').html())
    events:
      "click #event-order .choice": "reorder"
      "click #add-event": "show_event_edit"
      "click #add-contest": "show_contest_edit"
    show_event_edit: ->
      show_event_edit(new $ed.EventItemModel(kind:"party",id:"party"))
    show_contest_edit: ->
      show_event_edit(new $ed.EventItemModel(kind:"contest",id:"contest"))
    reorder: (ev) ->
      target = $(ev.currentTarget)
      order = target.data("order")
      @collection.set_comparator(order)
      @collection.sort()
    initialize: ->
      _.bindAll(this,"render","reorder")
      @collection = new EventListCollection()
      @listenTo(@collection,"sort", @render)
      @collection.set_comparator('date')
      @collection.fetch()
    render: ->
      @$el.html(@template())
      @$el.find(".choice[data-order='#{@collection.order}']").addClass("active")
      @subviews = []
      has_deadline_alert = false
      for m in @collection.models
        v = new EventItemView(model:m)
        v.render()
        @$el.find(".event-body").append(v.$el)
        @subviews.push(v)
        if m.get('deadline_alert') and not m.get('forbidden') and not m.get('choice')
          has_deadline_alert = true
          av = new EventAbbrevView(model:m,choice_model:v.choice_model)
          av.render()
          @$el.find(".deadline-message").append(av.$el)
      if has_deadline_alert
        @$el.find(".deadline-message").show()

  EventChoiceModel = Backbone.Model.extend
    urlRoot: "api/event/choose/"

  EventChoiceView = Backbone.View.extend
    el: "<dd class='sub-nav'>"
    template: _.template_braces($("#templ-event-choice").html())
    template_alert: _.template($("#templ-sticky-alert").html())
    events:
      "click .choice" : "do_when_click"
    initialize: ->
      _.bindAll(this,"render")
      @listenTo(@model,"change",@render)
    do_when_click: (ev)->
      ct = $(ev.currentTarget)
      id = ct.data('id')
      @model.set('id',id)
      that = this
      @model.save().done((data)->
        c = $("#sticky-alert-container")
        if c.find("#sticky-alert").length == 0
          c.append(that.template_alert())
        c.find(".content").append($("<div/>",{html:"登録完了: #{that.options.event_name} &rArr; #{ct.text()}"}))
        that.options.parent.$el.find(".participant-count").text(data.count)
      )
    render: ->
      choices = @model.get("choices")
      data = {data:
        x for x in choices
      }
      @$el.html(@template(data))
      @$el.find("dd[data-id='#{@model.get('id')}']").addClass("active")
  EventEditView = Backbone.View.extend
    template_choice: _.template_braces($("#templ-choice-item").html())
    events:
      "click .choice-name" : "edit_choice"
      "click .choice-delete" : "delete_choice"
      "click #add-choice" : "add_choice"
      "change #event-groups" : "group_change"
      "change #cur-group-list" : "copy_info"
      "click #add-contest-group" : "add_contest_group"
    add_contest_group: ->
      if r = prompt("追加する恒例大会名:")
        $.post("api/event/group/new",name:r).done((data)->
          $("#event-groups").append($($.parseHTML(_.make_option(data.id,{value:data.id,text:data.name}))))
        )
      false
    copy_info: ->
      gid = parseInt($("#event-groups").val())
      id = parseInt($("#cur-group-list").val())
      m = new $ed.EventItemModel(id:id)
      that = this
      m.fetch(data:{detail:true,edit:true}).done(->
        that.model.set(m.pick(
          "name","formal_name","place","description",
          "forbidden_attrs","hide_choice","official",
          "team_size", "aggregate_attr_id","start_at","end_at"
        ))
        console.log m.pick("aggregate_attr_id")
        that.model.set("event_group_id",gid)

        ev = new EventEditInfoView(model:that.model)
        ev.render()
        that.$el.find("#event-edit-info").empty()
        that.$el.find("#event-edit-info").append(ev.$el)
        that.group_change(id)
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
      if r = prompt("選択肢名:")
        o = $("<div>",html:@template_choice(x:{positive:true,name:r,id:-1}))
        $("#edit-choice-list").find("[data-positive='false']").first().before(o)

    delete_choice: (ev) ->
      $(ev.currentTarget).parent(".choice-item").remove()
    initialize: ->
      @render()
    render: ->
      @$el.html($("#templ-event-edit").html())
      ev = new EventEditInfoView(model:@model)
      @edit_info_view = ev
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
      _.save_model_alert(m,{log:@edit_log},["log"]).done(->
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
      name = prompt("名前")
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
      @$el.html("<button data-toggle-text='キャンセル' class='toggle-edit small round'>編集開始</button> <button class='apply-edit small round hide'>更新</button>"+@template(data:data))

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
      "submit #event-edit-form" : "do_submit"
    delete_event: ->
      if prompt("削除するにはdeleteと入れて下さい") == "delete"
        @model.destroy().done(-> alert("削除しました"))
      false
    do_submit: ->
      obj = $("#event-edit-form").serializeObj()
      obj["choices"] = get_edit_choice_list()
      m = @model
      if m.get("id") == "contest" || m.get("id") == "party"
        m.unset("id")
      is_new = m.isNew()
      _.save_model_alert(@model,obj).done(->
        $("#container-event-edit").foundation("reveal","close")
        if is_new
          window.event_list_view.collection.add(m))

      false
    initialize: ->
      @listenTo(@model,"sync",@render)
    render: ->
      @$el.html(@template(data:@model.toJSON()))
      # we have to set width explicitly to use chosen inside zurb foundation's section
      @$el.find("[name='forbidden_attrs']").chosen(
        width: "100%"
      )
  NewlyMessageModel = Backbone.Model.extend
    url: "api/user/newly-message"
  NewlyMessageView = Backbone.View.extend
    el: "#newly-message"
    initialize: ->
      @listenTo(@model,"sync",@render)

  init: ->
    window.show_schedule_weekday = true
    window.show_schedule_month = true
    window.schedule_panel_view = new SchedulePanelView()
    window.event_list_view = new EventListView()
    $si.init()
