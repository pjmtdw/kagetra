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

  init: ->
    window.show_schedule_weekday = true
    window.show_schedule_month = true
    window.schedule_panel = new SchedulePanelView()
    window.schedule_detail_view = new $si.ScheduleDetailView(parent:window.schedule_panel)
