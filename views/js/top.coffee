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
      sign = if attr in ["created_at","participant"] then -1 else 1
      f = if attr in ["created_at","date"]
            (x)-> x.get(attr) || ("9999-12-31_" + x.get("name"))
          else if attr == "participant"
            (x)-> x.get(attr)
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
    events:
      "click .show-detail": "do_when_click"
    render: ->
      this.$el.html(this.template
        name:this.model.get('name'),
        date:this.model.get('date'),
        deadline:show_deadline(this.model.get('deadline_day'))
        participant:this.model.get('participant')
        )
    initialize: ->
      _.bindAll(this,"do_when_click")
    do_when_click: ->
      window.event_detail_view.$el.foundation("reveal","open")
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
      this.collection.bind("sort", this.render, this)
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
        cm = new EventChoiceModel({choices:m.get('choices'),choice:m.get('choice'),eid:m.get('id')})
        cv = new EventChoiceView(model:cm)
        cv.render()
        v.$el.find(".event-choice").append(cv.$el)
        that.subviews.push(v)
      
  EventDetailView = Backbone.View.extend
    el: "#container-event-detail"
    template: _.template($("#templ-event-detail").html())
  EventChoiceModel = Backbone.Model.extend {
    url: -> "/api/event/choose/#{this.get('eid')}/#{this.get('choice')}"
  }
  EventChoiceView = Backbone.View.extend
    el: "<dd class='sub-nav'>"
    template: _.template_braces($("#templ-event-choice").html())
    events:
      "click .choice" : "do_when_click"
    initialize: ->
      _.bindAll(this,"do_when_click")
      this.model.bind("change",this.render,this)
    do_when_click: (ev)->
      id = $(ev.currentTarget).attr('data-id')
      this.model.set('choice',id)
      this.model.save()
    render: ->
      choices = this.model.get("choices")
      data = {data:
        {name:x.name,id:x.id} for x in choices
      }
      this.$el.html(this.template(data))
      console.log this.model.get('choice')
      this.$el.find("dd[data-id='#{this.model.get('choice')}']").addClass("active")

  init: ->
    window.show_schedule_weekday = true
    window.show_schedule_month = true
    window.schedule_panel_view = new SchedulePanelView()
    window.event_list_view = new EventListView()
    window.event_detail_view = new EventDetailView()
    window.schedule_detail_view = new $si.ScheduleDetailView(parent:window.schedule_panel)
