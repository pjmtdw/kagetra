define (require,exports,module) ->
  $si = require("schedule_item")
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
      f = (x)-> x.get(attr) || ("9999-12-31_" + x.get("name"))
      this.comparator = (x,y) -> fx=f(x);fy=f(y);if fx>fy then sign else if fx<fy then -sign else 0
  EventItemView = Backbone.View.extend
    template: _.template($('#templ-event-item').html())
    render: ->
      this.$el.html(this.template(name:this.model.get('name'),date:this.model.get('date')))

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
      this.collection.set_comparator('created_at')
      this.collection.fetch()
    render: ->
      this.$el.html(this.template())
      this.$el.find(".choice[data-order='#{this.collection.order}']").addClass("active")
      that = this
      this.subviews = []
      this.collection.each (m)->
        v = new EventItemView(model:m)
        v.render()
        that.$el.find(".body").append(v.$el)
        that.subviews.push(v)
      

  init: ->
    window.show_schedule_weekday = true
    window.show_schedule_month = true
    window.schedule_panel_view = new SchedulePanelView()
    window.event_list_view = new EventListView()
    window.schedule_detail_view = new $si.ScheduleDetailView(parent:window.schedule_panel)
