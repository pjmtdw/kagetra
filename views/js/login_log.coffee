define (require,exports,module) ->
  LoginWeeklyModel = Backbone.Model.extend
    url: "api/login_log/weekly"
  LoginWeeklyView = Backbone.View.extend
    template: _.template($("#templ-login-weekly").html())
    initialize: ->
      @model = new LoginWeeklyModel()
      @listenTo(@model,"sync",@render)
      @model.fetch()
    render: ->
      @$el.html(@template(data:@model.toJSON()))
      @$el.appendTo("#login-weekly")
  LoginTotalModel = Backbone.Model.extend
    url: "api/login_log/total"
  LoginTotalView = Backbone.View.extend
    template: _.template($("#templ-login-total").html())
    initialize: ->
      @model = new LoginTotalModel()
      @listenTo(@model,"sync",@render)
      @model.fetch()
    render: ->
      @$el.html(@template(data:@model.toJSON()))
      @$el.appendTo("#login-total")
  LoginRankingModel = Backbone.Model.extend
    url: "api/login_log/ranking"
  LoginRankingView = Backbone.View.extend
    template_table: _.template_braces($("#templ-login-table").html())
    initialize: ->
      @model = new LoginRankingModel()
      @listenTo(@model,"sync",@render)
      @model.fetch()
    render: ->
      console.log @model.get("prev")
      h_cur = @template_table(title:"今月",data:@model.get("cur"),names:@model.get("names"))
      h_prev = @template_table(title:"先月",data:@model.get("prev"),names:@model.get("names"))
      @$el.html($("#templ-login-ranking").html())
      @$el.find(".body").html(h_cur + h_prev)
      @$el.appendTo("#login-ranking")

  switch_view = (ev)->
    kwd = _.last($(ev.currentTarget).attr("href").split("#"))
    kwd_to_klass = {
      ranking: LoginRankingView
      weekly: LoginWeeklyView
      total: LoginTotalView
    }
    if not ("login_log_#{kwd}" of window)
      window["login_log_#{kwd}"] = new kwd_to_klass[kwd]()
  init: ->
    window["login_log_ranking"] = new LoginRankingView()
    $(".section-container.tabs a").on("click",switch_view)
    
