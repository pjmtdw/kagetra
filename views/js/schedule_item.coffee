define ->
  _.mixin
    show_item_detail: (data)->
      hm = if data.start_at or data.end_at
        c1 = if data.emph_start_at then "emphasis" else ""
        c2 = if data.emph_end_at then "emphasis" else ""
        "[ <span class='hourmin #{c1}'>#{data.start_at ? ''}</span> &sim; <span class='hourmin #{c2}'>#{data.end_at ? ''}</span> ] "
      pl = if data.place
        c = if data.emph_place then "emphasis" else ""
        " @ <span class='place #{c}'>#{data.place ? ''}</span>"
      ds = if data.description
        "<div class='description panel left'>#{data.description}</div>"
      tt = if data.title or data.name
        c = if data.emph_title then "emphasis" else ""
        "<span class='title #{c}'>#{data.title or data.name}</span>"
      ss = (hm ? '') + (tt ? '') + (pl ? '')
      "<div>#{ss}</div>" + (ds ? '')
  ScheduleModel = Backbone.Model.extend
    url: ->
      [y,m,d] = (@get(x) for x in ['year','mon','day'])
      "/api/schedule/get/#{y}/#{m}/#{d}"
    parse: (data)->
      data.current = true unless data.current?
      data

  ScheduleItemView = Backbone.View.extend
    events:
      "click":"do_when_click"
    template: _.template($("#templ-schedule-item").html())
    template_edit_info: _.template($("#templ-schedule-item-edit-info").html())
    el: "<li>"
    initialize: ->
      _.bindAll(this,"do_when_click","refresh","render")
    refresh: ->
      @model.fetch().done(@render)
    do_when_click: ->
      return if @edit_info or not @model.get('current')
      window.schedule_detail_view.$el.foundation("reveal","open")
      [year,mon,day] = (@model.get(x) for x in ['year','mon','day'])
      window.schedule_detail_view.refresh(year,mon,day)
    get_date: ->
      if @model.get('current')
        _.gen_date(@model)
    show_day: (date) ->
      date = if date? then date else @get_date()
      if date
        (if window.show_schedule_month then "#{date.getMonth()+1} / " else "") +
        date.getDate() +
        (if window.show_schedule_weekday then " (#{_.weekday_ja()[date.getDay()]})" else "")
    render: ->
      @edit_info = false
      info = @model.get('info')
      date = @get_date()
      @$el.html(@template(
            item: @model.get('item')
            event: @model.get('event')
            info: info
            day: @show_day(date)
      ))
      info_item = @$el.find(".info-item")
      if @model.get('current')
        info_item.addClass("current")
        today = new Date()
        if today.toDateString() == date.toDateString()
          info_item.addClass('today')
        if (info and info.is_holiday) or (date.getDay() == 0)
          info_item.addClass("holiday")
        else if date.getDay() == 6
          info_item.addClass("saturday")
        else
          info_item.addClass("weekday")
      else
        info_item.addClass("not-current")
    render_edit_info: ->
      @edit_info = true
      info = @model.get('info')
      @$el.html(@template_edit_info(
        info: info
        day: @show_day()
      ))
      if info and info.is_holiday
        @$el.find(".holiday").prop("checked",true)
      if not @model.get('current')
        @$el.find(".info-item-edit").addClass("not-current-edit")

  ScheduleDetailModel = Backbone.Model.extend
    urlRoot: "/api/schedule/detail/update"

  ScheduleDetailCollection = Backbone.Collection.extend
    model: ScheduleDetailModel
    refresh: (year,mon,day) ->
      @url = "/api/schedule/detail/#{year}/#{mon}/#{day}"
    parse: (data) ->
      @year = data.year
      @mon = data.mon
      @day = data.day
      @day_infos = data.day_infos
      @events = data.events
      data.list
  ScheduleDetailItemView = Backbone.View.extend
    template: _.template($("#templ-schedule-detail-item").html())
    template_edit: _.template_braces($("#templ-schedule-detail-item-edit").html())
    events:
      "click .edit":"toggle_edit"
      "click .edit-cancel":"toggle_edit"
      "click .edit-done":"edit_done"
    edit_done: ->
      obj = @$el.find('.item-detail-form').serializeObj()
      @model.set(obj)
      refresh_day = ->
        dv = window.schedule_detail_view
        [year,mon,day] = (dv.collection[x] for x in ["year","mon","day"])
        dv.parent.get_subview(year,mon,day).refresh()
      if @model.isNew()
        @model.save().done(->
          window.schedule_detail_view.refresh()
          refresh_day()
        )
      else
        that = this
        @model.save().done(->
          that.toggle_edit()
          refresh_day()
        )
    toggle_edit: ->
      if @model.isNew()
        @$el.remove()
      else
        @edit_mode ^= true
        if @edit_mode
          @render_edit()
        else
          @render()
    initialize: ->
      @edit_mode = false
      _.bindAll(this,"toggle_edit","edit_done")
    render: ->
      @$el.html(@template(data:@model.toJSON()))
    render_edit: ->
      @edit_mode = true
      @$el.html(@template_edit(data:@model.toJSON()))
      @$el.checkboxApply()
      @$el.foundation("forms","init")
  ScheduleDetailEventView = Backbone.View.extend
    events:
      "click .detail" : "show_detail"
      "click .comment" : "show_comment"
    show_detail: ->
      dv = window.event_detail_view
      dv.reveal(@data.id)
    show_comment: ->
      window.event_comment_view.reveal(@data.id)
    template: _.template($("#templ-schedule-detail-event").html())
    initialize: (arg) -> @data = arg.data

    render: ->
      @$el.html(@template(data:@data))

  ScheduleDetailView = Backbone.View.extend
    el: '#container-schedule-detail'
    template: _.template($("#templ-schedule-detail").html())
    events:
      "click #add-new-item": "do_add_new"
    do_add_new: ->
      m = new ScheduleDetailModel(year:@collection.year,mon:@collection.mon,day:@collection.day)
      v = new ScheduleDetailItemView(model:m)
      $("#container-new-item").empty()
      v.render_edit()
      $("#container-new-item").append(v.$el)
     initialize: (opts)->
      _.bindAll(this,"render","do_add_new")
      @parent = opts.parent
      @collection = new ScheduleDetailCollection()
    refresh: (year,mon,day) ->
      if year?
        @collection.refresh(year,mon,day)
      else
      @collection.fetch().done(@render)
    render: ->

      [year,mon,day] = (@collection[x] for x in ["year","mon","day"])
      date = _.gen_date(year,mon,day)
      di = @collection.day_infos
      names = if di then di.names
      is_holiday = if di then di.holiday
      @$el.html(@template(data:
        is_holiday: is_holiday
        day_infos: names
        year: year
        mon: mon
        day: day
        wday: _.weekday_ja()[date.getDay()]
      ))
      body =@$el.find('.body')
      for m in @collection.events
        v = new ScheduleDetailEventView(data:m)
        v.render()
        body.append(v.$el)
      for m in @collection.models
        v = new ScheduleDetailItemView(model:m)
        v.render()
        body.append(v.$el)
  {
    ScheduleDetailView: ScheduleDetailView
    ScheduleModel: ScheduleModel
    ScheduleItemView: ScheduleItemView
  }
