define (require,exports,module) ->
  # Requirng schedule_item in multiple scripts cause minified file larger
  # since both scripts contains whole content of schedule_item.js.
  # TODO: do not require schedule_item here and load it dynamically.
  $si = require("schedule_item")
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

  ScheduleCollection = Backbone.Collection.extend
    model: $si.ScheduleModel
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
    initialize: ->
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
        v = new $si.ScheduleItemView(model:m)
        if that.edit_info
          v.render_edit_info()
        else
          v.render()
        if not window.is_small or m.get('current')
          $("#cal-body").append(v.$el)
        that.subviews.push(v)
  init: ->
    window.schedule_router = new ScheduleRouter()
    window.schedule_view = new ScheduleView()
    window.schedule_detail_view = new $si.ScheduleDetailView()
    Backbone.history.start()
