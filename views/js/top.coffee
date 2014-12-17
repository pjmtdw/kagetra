define (require,exports,module) ->
  $ed = require("event_detail")
  $si = require("schedule_item")
  $co = require("comment")
  _.mixin
    show_news: (arr,attr,msg,href)->
      return "" if _.isEmpty(arr)
      buf = msg.replace("%%",arr.length)
      buf += ": "
      rs = []
      for x in arr[0..10]
        hr = href.replace("%id%",x.id).replace("%page%",x.page)
        rs.push("<a href='#{hr}'>#{x[attr]}</a>")
      buf += rs.join(" / ")
      buf
    show_date: (s) ->
      return "なし" unless s
      today = new Date()
      # parseIntの二つ目の引数を与えないと "08", "09" が 0 になってしまう．
      [y,m,d] = (parseInt(x,10) for x in s.split('-'))
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
      sign = if attr in ["created_at","last_comment_date","participant_count"] then -1 else 1
      ETERNAL_FUTURE = "9999-12-31_"
      ETERNAL_PAST = "0000-01-01_"
      f = if attr in ["created_at","date","last_comment_date"]
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
  EventItemBaseView = Backbone.View.extend
    events:
      "click .show-detail": "show_detail"
      "click .show-group": "show_group"
      "click .show-comment": "show_comment"
    initialize: ->
      @listenTo(@model,"sync",@render)
    show_group: ->
      $ed.show_event_group(@model.get('event_group_id'))
    show_detail: ->
      ecv = if _.isNull(@model.get('choice'))
              [cm,cv] = @gen_event_choice_model_view()
              cv
            else undefined
      $ed.reveal_detail("#container-event-detail",@model,ecv)
    show_comment: ->
      $co.reveal_comment("event","#container-event-comment",@model.get('id'),@$el.find(".event-comment-count"),$ed.additional_data(@model.get('id')))
    gen_event_choice_model_view: ->
      if not @options.choice_model
        @options.choice_model = new EventChoiceModel(choices:@model.get('choices'),id:@model.get('choice'))
      cm = @options.choice_model
      cv = new EventChoiceView(model:cm,event_name:@model.get('name'))
      cv.render()
      [cm,cv]
    render: ->
      # render は model が sync する度に呼ばれることに注意 (「情報」ボタンを押しても sync される !)
      # TODO: 情報ボタンを押した時とかにいちいち sync しない
      json = @model.toJSON()
      json.deadline_str = show_deadline(json.deadline_day)
      @$el.html(@template(data:json))
      if json.deadline_day? and json.deadline_day < 0
        # 締切を過ぎているので何も表示しない
      else if not json.forbidden
        [cm,cv] = @gen_event_choice_model_view()
        @$el.find(".event-choice").append(cv.$el)
      else
        @$el.find(".event-choice").append($("<span>",class:"forbidden",text:"貴方は登録不可です"))
      @choice_model = cm

  EventItemView = EventItemBaseView.extend
    el: '<li>'
    template: _.template_braces($('#templ-event-item').html())
    events: ->
      _.extend(EventItemBaseView.prototype.events,
      "click .show-edit": -> $ed.show_event_edit(@model)
      )

  EventAbbrevView = EventItemBaseView.extend
    template: _.template($('#templ-event-abbrev').html())
  EventAfterView = EventItemBaseView.extend
    template: _.template($('#templ-event-after').html())

  EventListView = Backbone.View.extend
    el: '#event-list'
    template: _.template($('#templ-event-list').html())
    events:
      "click #event-order .choice": "reorder"
      "click #add-event": "show_event_edit"
      "click #add-contest": "show_contest_edit"
    show_event_edit: ->
      $ed.show_event_edit(new $ed.EventItemModel(kind:"party",id:"party"))
    show_contest_edit: ->
      $ed.show_event_edit(new $ed.EventItemModel(kind:"contest",id:"contest"))
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
      deadline_before = @$el.find(".deadline-message .deadline-before")
      deadline_after = @$el.find(".deadline-message .deadline-after")
      for m in @collection.models
        v = new EventItemView(model:m)
        v.render()
        @$el.find(".event-body").append(v.$el)
        @subviews.push(v)
        if m.get('deadline_alert') and not m.get('forbidden') and not m.get('choice')
          av = new EventAbbrevView(model:m,choice_model:v.choice_model)
          av.render()
          deadline_before.find(".body").append(av.$el)
          deadline_before.show()
        if m.get('deadline_after')
          av = new EventAfterView(model:m)
          av.render()
          deadline_after.find(".body").append(av.$el)
          deadline_after.show()
      if deadline_before.find('.body').children().length > 0 or deadline_after.find('.body').children().length > 0
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
        if data._error_?
          _.cb_alert("エラー: " + data._error_)
        else
          c = $("#sticky-alert-container")
          if c.find("#sticky-alert").length == 0
            c.append(that.template_alert())
          c.find(".content").append($("<div/>",{html:"登録完了: #{data.event_name} &rArr; #{ct.text()}"}))
          $(".event-item[data-id='#{data.event_id}']").find(".participant-count").text(data.count)
      )
    render: ->
      choices = @model.get("choices")
      data = {data:
        x for x in choices
      }
      @$el.html(@template(data))
      @$el.find("dd[data-id='#{@model.get('id')}']").addClass("active")
  NewlyMessageModel = Backbone.Model.extend
    url: "api/user/newly_message"
  NewlyMessageView = Backbone.View.extend
    el: "#newly-message"
    events:
      "click #event-comment-new a" : "show_event_comment"
      "click .link-detail a" : "show_event_detail"
      "click .login-elapsed.countable" : "relogin"
    relogin: ->
      $.post("api/user/relogin").done(-> location.reload(false))
    show_event_comment: (ev)->
      id = _.last($(ev.currentTarget).attr("href").split("/"))
      $(".event-item[data-id='#{id}'] .show-comment").trigger("click")
      false
    show_event_detail: (ev)->
      id = _.last($(ev.currentTarget).attr("href").split("/"))
      $(".event-item[data-id='#{id}'] .show-detail").trigger("click")
      false
    template: _.template_braces($("#templ-newly-message").html())
    initialize: ->
      @model = new NewlyMessageModel()
      @listenTo(@model,"sync",@render)
      @model.fetch()
    render: ->
      @$el.html(@template(data:@model.toJSON()))

  init: ->
    window.show_schedule_weekday = true
    window.show_schedule_month = true
    window.schedule_panel_view = new SchedulePanelView()
    window.event_list_view = new EventListView()
    window.newly_message_view = new NewlyMessageView()
    $si.init()
