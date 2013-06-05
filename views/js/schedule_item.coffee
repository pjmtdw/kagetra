define ->
  ScheduleModel = Backbone.Model.extend {
    url: ->
      [y,m,d] = (this.get(x) for x in ['year','mon','day'])
      "/api/schedule/get/#{y}/#{m}/#{d}"
    parse: (data)->
      data.current = true unless data.current?
      data
  }
  ScheduleItemView = Backbone.View.extend
    events:
      "click":"do_when_click"
    template: _.template($("#templ-schedule-item").html())
    template_edit_info: _.template($("#templ-schedule-item-edit-info").html())
    el: "<li>"
    initialize: ->
      _.bindAll(this,"do_when_click","refresh","render")
    refresh: ->
      this.model.fetch().done(this.render)
    do_when_click: ->
      return if this.edit_info or not this.model.get('current')
      window.schedule_detail_view.$el.foundation("reveal","open")
      [year,mon,day] = (this.model.get(x) for x in ['year','mon','day'])
      window.schedule_detail_view.refresh(year,mon,day)
    get_date: ->
      if this.model.get('current')
        _.gen_date(this.model)
    show_day: (date) ->
      date = if date? then date else this.get_date()
      if date
        (if window.show_schedule_month then "#{date.getMonth()+1} / " else "") +
        date.getDate() +
        (if window.show_schedule_weekday then " (#{_.weekday_ja()[date.getDay()]})" else "")
    render: ->
      this.edit_info = false
      info = this.model.get('info')
      date = this.get_date()
      this.$el.html(this.template(
            item: this.model.get('item')
            info: info
            day: this.show_day(date)
      ))
      info_item = this.$el.find(".info-item")
      if this.model.get('current')
        info_item.addClass("current")
        if (info and info.is_holiday) or (date.getDay() == 0)
          info_item.addClass("holiday")
        else if date.getDay() == 6
          info_item.addClass("saturday")
        else
          info_item.addClass("weekday")
      else
        info_item.addClass("not-current")
    render_edit_info: ->
      this.edit_info = true
      info = this.model.get('info')
      this.$el.html(this.template_edit_info(
        info: info
        day: this.show_day()
      ))
      if info and info.is_holiday
        this.$el.find(".holiday").prop("checked",true)
      if not this.model.get('current')
        this.$el.find(".info-item-edit").addClass("not-current-edit")
        
  ScheduleDetailModel = Backbone.Model.extend {
    urlRoot: "/api/schedule/detail/update"
    defaults:
      title: ""
      place: ""
      start_at: ""
      end_at: ""
      description: ""
  }
  ScheduleDetailCollection = Backbone.Collection.extend
    model: ScheduleDetailModel
    refresh: (year,mon,day) ->
      this.url = "/api/schedule/detail/#{year}/#{mon}/#{day}"
    parse: (data) ->
      this.year = data.year
      this.mon = data.mon
      this.day = data.day
      data.list
  ScheduleDetailItemView = Backbone.View.extend
    template: _.template($("#templ-schedule-detail-item").html())
    template_edit: _.template_braces($("#templ-schedule-detail-item-edit").html())
    events:
      "click .edit":"toggle_edit"
      "click .edit-cancel":"toggle_edit"
      "click .edit-done":"edit_done"
    edit_done: ->
      obj = this.$el.find('.item-detail-form').serializeObj()
      this.model.set(obj)
      that = this
      refresh_day = ->
        dv = window.schedule_detail_view
        [year,mon,day] = (dv.collection[x] for x in ["year","mon","day"])
        dv.parent.get_subview(year,mon,day).refresh()
      if this.model.isNew()
        this.model.save().done(->
          window.schedule_detail_view.refresh()
          refresh_day()
        )
      else
        this.model.save().done(->
          that.toggle_edit()
          refresh_day()
        )
    toggle_edit: ->
      if this.model.isNew()
        this.$el.remove()
      else
        this.edit_mode ^= true
        if this.edit_mode
          this.render_edit()
        else
          this.render()
    initialize: ->
      this.edit_mode = false
      _.bindAll(this,"toggle_edit","edit_done")
    render: ->
      this.$el.html(this.template(this.model.toJSON()))
    render_edit: ->
      this.edit_mode = true
      this.$el.html(this.template_edit(this.model.toJSON()))
  ScheduleDetailView = Backbone.View.extend
    el: '#container-schedule-detail'
    template: _.template($("#templ-schedule-detail").html())
    events:
      "click #add-new-item": "do_add_new"
    do_add_new: ->
      m = new ScheduleDetailModel(year:this.collection.year,mon:this.collection.mon,day:this.collection.day)
      v = new ScheduleDetailItemView(model:m)
      $("#container-new-item").empty()
      v.render_edit()
      $("#container-new-item").append(v.$el)
     initialize: (opts)->
      _.bindAll(this,"render","do_add_new")
      this.parent = opts.parent
      this.collection = new ScheduleDetailCollection()
    refresh: (year,mon,day) ->
      if year?
        this.collection.refresh(year,mon,day)
      else
      this.collection.fetch().done(this.render)
    render: ->

      [year,mon,day] = (this.collection[x] for x in ["year","mon","day"])
      date = _.gen_date(year,mon,day)
      this.$el.html(this.template(
        year: year
        mon: mon
        day: day
        wday: _.weekday_ja()[date.getDay()]
      ))
      that = this
      this.collection.each (m)->
        v = new ScheduleDetailItemView(model:m)
        v.render()
        that.$el.find('.body').append(v.$el)
  {
    ScheduleDetailView: ScheduleDetailView
    ScheduleModel: ScheduleModel
    ScheduleItemView: ScheduleItemView
  }
