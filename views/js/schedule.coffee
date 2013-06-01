define ->
  ScheduleRouter = Backbone.Router.extend
    routes:
      "cal/:year/:mon": "cal",
      "": "start"
    start: ->
      dt = new Date()
      mon = dt.getMonth() + 1
      year = dt.getFullYear()
      window.schedule_router.navigate("cal/#{year}/#{mon}", {trigger: true, replace: true})
    cal: (year,mon) ->
      window.schedule_view.refresh(year,mon)

  ScheduleModel = Backbone.Model.extend {
    url: ->
      [y,m,d] = (this.get(x) for x in ['year','mon','day'])
      "/api/schedule/get/#{y}/#{m}/#{d}"
    parse: (data)->
      data.current = true unless data.current?
      data
  }
  ScheduleCollection = Backbone.Collection.extend
    model: ScheduleModel
    refresh: (year,mon) ->
      this.url = "/api/schedule/cal/#{year}/#{mon}"
    parse: (data) ->
      this.year = data.year
      this.mon = data.mon
      this.before_day = data.before_day
      bef = if data.before_day > 0
              for i in [1..data.before_day]
                {current: false}
            else
                []
      cur = for i in [1..data.month_day]
              {current: true
              year: this.year
              mon: this.mon
              day: i
              info: data.day_infos[i.toString()]
              item: data.items[i.toString()]}
      aft = if data.after_day > 0
              for i in [1..data.after_day]
                {current: false}
            else
               []
      bef.concat(cur.concat(aft))
    
  ScheduleItemView = Backbone.View.extend
    events:
      "click":"do_when_click"
    template: _.template($("#templ-item").html())
    template_edit_info: _.template($("#templ-item-edit-info").html())
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
        this.model.get('day').toString() +
          (if window.is_small then "(#{_.weekday_ja()[date.getDay()]})" else "")
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
        
  ScheduleView = Backbone.View.extend
    el: "#schedule"
    events:
      "click #edit-info-done":"do_edit_info_done"
      "click #prev-month": -> this.inc_month(-1)
      "click #next-month": -> this.inc_month(1)
      "click .toggle-edit-info": "do_toggle_edit_info"
    refresh: (year,mon) ->
      this.collection.refresh(year,mon)
      this.collection.fetch().done(this.render)

    inc_month: (dx) ->
      m = this.collection.mon
      y = this.collection.year
      x = y * 12 + ( m - 1 ) + dx
      mm = (x % 12) + 1
      yy = Math.floor(x / 12)
      window.schedule_router.navigate("cal/#{yy}/#{mm}", trigger: true)
    do_toggle_edit_info: ->
      this.edit_info ^= true
      this.render()
    template: _.template($("#templ-cal-header").html()+$("#templ-cal").html())
    template_edit: _.template($("#templ-cal-edit-header").html()+$("#templ-cal").html())
    initialize: (opts) ->
      _.bindAll(this,"render","do_edit_info_done","do_toggle_edit_info","inc_month")
      this.collection = new ScheduleCollection()
    get_subview: (day) ->
      this.subviews[this.collection.before_day+day-1]
    do_edit_info_done: ->
      have_to_update = {}
      for v in this.subviews
        val= v.$el.find(".info").val()
        names_new = if !!val then val.split("\n") else []
        minfo = v.model.get("info")
        names_old = if minfo then minfo.names else []
        holiday_old = if minfo then !! minfo.is_holiday else false
        holiday_new = v.$el.find(".holiday").is(":checked")
        
        if "#{names_new}" != "#{names_old}" or holiday_old != holiday_new
          [year,mon,day] = (v.model.get(x) for x in ["year","mon","day"])
          have_to_update["#{year}-#{mon}-#{day}"] = {
            names: names_new
            holiday: holiday_new
          }
      if not _.isEmpty(have_to_update)
        this.save(have_to_update)
      else
        this.do_toggle_edit_info()
    save: (have_to_update)->
      res = Backbone.sync('update',this,
        method:'post',
        url:'/api/schedule/update_holiday',
        contentType:'application/json',
        data:JSON.stringify(have_to_update))
      that = this
      res.done( ->
        that.collection.fetch().done(that.do_toggle_edit_info)
      )
                
    render: ->
      templ = if this.edit_info then this.template_edit else this.template
      this.$el.html(templ(
            year: this.collection.year
            mon: this.collection.mon
      ))
      that = this
      this.subviews = []
      if not window.is_small
        for x in _.weekday_ja()
          $("#cal-body").append($("<li>#{x}</li>"))
      this.collection.each (m) ->
        v = new ScheduleItemView(model:m)
        if that.edit_info
          v.render_edit_info()
        else
          v.render()
        if not window.is_small or m.get('current')
          $("#cal-body").append(v.$el)
        that.subviews.push(v)
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
    template: _.template($("#templ-detail-item").html())
    template_edit: _.template($("#templ-detail-item-edit").html(),false,interpolate: /\{\{(.+?)\}\}/g)
    events:
      "click .edit":"toggle_edit"
      "click .edit-cancel":"toggle_edit"
      "click .edit-done":"edit_done"
    edit_done: ->
      obj = this.$el.find('.item-detail-form').serializeObj()
      this.model.set(obj)
      that = this
      refresh_day = ->
          day = window.schedule_detail_view.collection.day
          window.schedule_view.get_subview(day).refresh()
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
    el: '#container-detail'
    template: _.template($("#templ-detail").html())
    events:
      "click #add-new-item": "do_add_new"
    do_add_new: ->
      m = new ScheduleDetailModel(year:this.collection.year,mon:this.collection.mon,day:this.collection.day)
      v = new ScheduleDetailItemView(model:m)
      $("#container-new-item").empty()
      v.render_edit()
      $("#container-new-item").append(v.$el)
     initialize: ->
      _.bindAll(this,"render","do_add_new")
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
  init: ->
    window.schedule_router = new ScheduleRouter()
    window.schedule_view = new ScheduleView()
    window.schedule_detail_view = new ScheduleDetailView()
    Backbone.history.start()
