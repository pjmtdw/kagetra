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
      window.schedule_view.refresh(year:year,mon:mon)

  ScheduleModel = Backbone.Model.extend {}
  ScheduleCollection = Backbone.Collection.extend
    model: ScheduleModel
    url: "/api/schedule/cal"
    refetch: ->
      this.fetch(data:{year:this.year,mon:this.mon})
    parse: (data) ->
      this.year = data.year
      this.mon = data.mon
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
    template: _.template($("#templ-item").html())
    template_edit_info: _.template($("#templ-item-edit-info").html())
    el: "<li>"
    render: ->
      info = this.model.get('info')
      this.$el.html(this.template(
            item: this.model.get('item')
            info: info
            day: this.model.get('day')
      ))
      info_item = this.$el.find(".info-item")
      if this.model.get('current')
        info_item.addClass("current")
        dt = new Date(this.model.get('year'),this.model.get('mon')-1,this.model.get('day'))
        if (info and info.is_holiday) or (dt.getDay() == 0)
          info_item.addClass("holiday")
        else if dt.getDay() == 6
          info_item.addClass("saturday")
        else
          info_item.addClass("weekday")
      else
        info_item.addClass("not-current")
    render_edit_info: ->
      info = this.model.get('info')
      this.$el.html(this.template_edit_info(
        info: info
        day: this.model.get('day')
      ))
      if info and info.is_holiday
        this.$el.find(".holiday").prop("checked",true)
      if not this.model.get('current')
        this.$el.find(".info-item-edit").addClass("not-current-edit")
        
  ScheduleView = Backbone.View.extend
    el: "#schedule"
    events:
      "click #edit-info-done":"do_edit_info_done"
      "click #prev-month": -> add_month(-1)
      "click #next-month": -> add_month(1)
      "click .toggle-edit-info": "do_toggle_edit_info"
    do_toggle_edit_info: ->
      this.edit_info ^= true
      this.render()
    template: _.template($("#templ-cal-header").html()+$("#templ-cal").html())
    template_edit: _.template($("#templ-cal-edit-header").html()+$("#templ-cal").html())
    initialize: ->
      this.collection = new ScheduleCollection()
      _.bindAll(this,"render","do_edit_info_done","do_toggle_edit_info")
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
          year = v.model.get("year")
          mon = v.model.get("mon")
          day = v.model.get("day")
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
        that.collection.refetch().done(that.do_toggle_edit_info)
      )
                
    refresh: (data) ->
      this.collection.fetch(data:data).done(this.render)
    render: ->
      e = this.$el
      e.empty()
      body = []
      that = this
      this.subviews = []
      templ = if this.edit_info then this.template_edit else this.template
      this.$el.html(templ(
            year: this.collection.year
            mon: this.collection.mon
      ))
      this.collection.each (m) ->
        v = new ScheduleItemView(model:m)
        if that.edit_info
          v.render_edit_info()
        else
          v.render()
        $("#cal-body").append(v.$el)
        that.subviews.push(v)
  add_month = (dx) ->
    m = window.schedule_view.collection.mon
    y = window.schedule_view.collection.year
    x = y * 12 + ( m - 1 ) + dx
    mm = (x % 12) + 1
    yy = Math.floor(x / 12)
    window.schedule_router.navigate("cal/#{yy}/#{mm}", trigger: true)
  init: ->
    window.schedule_router = new ScheduleRouter()
    window.schedule_view = new ScheduleView()
    Backbone.history.start()
