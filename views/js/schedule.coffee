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
      @url = "/api/schedule/cal/#{year}-#{mon}"
    parse: (data) ->
      @year = data.year
      @mon = data.mon
      @before_day = data.before_day
      bef = if data.before_day > 0
              for i in [1..data.before_day]
                {current: false}
            else
                []
      cur = for i in [1..data.month_day]
              {current: true
              year: @year
              mon: @mon
              day: i
              info: data.day_infos[i.toString()]
              event: data.events[i.toString()]
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
      "click #prev-month": -> @inc_month(-1)
      "click #next-month": -> @inc_month(1)
      "click .toggle-edit-info": "do_toggle_edit_info"
    refresh: (year,mon) ->
      @collection.refresh(year,mon)
      @collection.fetch().done(@render)

    inc_month: (dx) ->
      m = @collection.mon
      y = @collection.year
      x = y * 12 + ( m - 1 ) + dx
      mm = (x % 12) + 1
      yy = Math.floor(x / 12)
      window.schedule_router.navigate("cal/#{yy}/#{mm}", trigger: true)
    do_toggle_edit_info: ->
      @edit_info ^= true
      @render()
    template: _.template($("#templ-cal-header").html()+$("#templ-cal").html())
    template_edit: _.template($("#templ-cal-edit-header").html()+$("#templ-cal").html())
    initialize: ->
      _.bindAll(this,"render","do_edit_info_done","do_toggle_edit_info","inc_month")
      @collection = new ScheduleCollection()
    do_edit_info_done: ->
      have_to_update = {}
      for v in @subviews
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
        @save(have_to_update)
      else
        @do_toggle_edit_info()
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
      templ = if @edit_info then @template_edit else @template
      @$el.html(templ(
            year: @collection.year
            mon: @collection.mon
      ))
      @subviews = []
      if not window.is_small
        for x,i in _.weekday_ja()
          ac = if i == 0
                 "weekday-sunday"
               else if i == 6
                 "weekday-saturday"
               else
                 ""
          $("#cal-body").append($("<li>",{text:x,class:"weekday-name #{ac}"}))
      for m in @collection.models
        v = new $si.ScheduleItemView(model:m)
        if @edit_info
          v.render_edit_info()
        else
          v.render()
        if not window.is_small or m.get('current')
          $("#cal-body").append(v.$el)
        @subviews.push(v)
  init: ->
    window.show_schedule_weekday = window.is_small
    window.schedule_router = new ScheduleRouter()
    window.schedule_view = new ScheduleView()
    $si.init()
    Backbone.history.start()
