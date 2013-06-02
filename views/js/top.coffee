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
      that = this
      this.collection.each (m)->
        v = new $si.ScheduleItemView(model:m)
        v.render()
        that.$el.append(v.$el)
  init: ->
    window.schedule_panel = new SchedulePanelView()
    window.schedule_detail_view = new $si.ScheduleDetailView()
