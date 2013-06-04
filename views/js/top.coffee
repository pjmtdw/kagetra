define (require,exports,module) ->
  $si = require("schedule_item")
  show_deadline = (deadline_day) ->
    if not deadline_day?
      ""
    else if deadline_day < 0
      "<span class='deadline-expired'>〆切を過ぎました</span>"
    else if deadline_day == 0
      "〆切は<span class='deadline-today'>今日</span>です"
    else if deadline_day == 1
      "〆切は<span class='deadline-tomorrow'>明日</span>です"
    else
      "〆切まであと<span class='deadline-future'>#{deadline_day}</span>日です"

  SchedulePanelCollection = Backbone.Collection.extend
    model: $si.ScheduleModel
    url: "/api/schedule/panel"
  SchedulePanelView = Backbone.View.extend
    el: '#schedule-panel'
    initialize: ->
      _.bindAll(this,"render")
      this.collection = new SchedulePanelCollection()
      this.collection.fetch().done(this.render)
    render: ->
      this.subviews = {}
      that = this
      this.collection.each (m)->
        v = new $si.ScheduleItemView(model:m)
        v.render()
        that.$el.append(v.$el)
        [y,m,d] = (m.get(x) for x in ["year","mon","day"])
        that.subviews["#{y}-#{m}-#{d}"] = v
    get_subview: (year,mon,day) ->
      this.subviews["#{year}-#{mon}-#{day}"]
  EventItemModel = Backbone.Model.extend {}
  EventListCollection = Backbone.Collection.extend
    model: EventItemModel
    url: "/api/event/list"
    set_comparator: (attr) ->
      this.order = attr
      sign = if attr == "created_at" then -1 else 1
      f = if attr == "created_at" or attr == "date"
            (x)-> x.get(attr) || ("9999-12-31_" + x.get("name"))
          else if attr == "deadline_day"
            (x)->
              dd = x.get("deadline_day")
              if not dd?
                999999999
              else if dd < 0
                999999 - dd
              else
                dd
      this.comparator = (x,y) -> fx=f(x);fy=f(y);if fx>fy then sign else if fx<fy then -sign else 0
  EventItemView = Backbone.View.extend
    el: '<li>'
    template: _.template($('#templ-event-item').html())
    render: ->
      this.$el.html(this.template(
        name:this.model.get('name'),
        date:this.model.get('date'),
        deadline:show_deadline(this.model.get('deadline_day'))))

  EventListView = Backbone.View.extend
    el: '#event-list'
    template: _.template($('#templ-event-list').html())
    events:
      "click #event-order .choice": "reorder"
    reorder: (ev) ->
      target = $(ev.currentTarget)
      order = target.attr("data-order")
      this.collection.set_comparator(order)
      this.collection.sort()
    initialize: ->
      _.bindAll(this,"reorder")
      this.collection = new EventListCollection()
      this.collection.bind("sort sync", this.render, this)
      this.collection.set_comparator('date')
      this.collection.fetch()
    render: ->
      this.$el.html(this.template())
      this.$el.find(".choice[data-order='#{this.collection.order}']").addClass("active")
      that = this
      this.subviews = []
      this.collection.each (m)->
        v = new EventItemView(model:m)
        v.render()
        that.$el.find(".event-body").append(v.$el)
        that.subviews.push(v)
      

  init: ->
    window.show_schedule_weekday = true
    window.show_schedule_month = true
    window.schedule_panel_view = new SchedulePanelView()
    window.event_list_view = new EventListView()
    window.schedule_detail_view = new $si.ScheduleDetailView(parent:window.schedule_panel)
