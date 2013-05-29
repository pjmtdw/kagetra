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
  ScheduleView = Backbone.View.extend
    el: "#schedule"
    template: _.template($("#templ-cal").html())
    initialize: ->
      this.collection = new ScheduleCollection()
      _.bindAll(this,"render")
    refresh: (data) ->
      this.collection.fetch(data:data).done(this.render)
    render: ->
      e = this.$el
      e.empty()
      body = []
      this.collection.each (m) ->
        v = new ScheduleItemView(model:m)
        v.render()
        body.push(v.$el.html())
      this.$el.html(this.template(
            year: this.collection.year
            mon: this.collection.mon
            body:body.join("")
            ))
      $("#prev-month").click(-> add_month(-1))
      $("#next-month").click(-> add_month(1))
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
