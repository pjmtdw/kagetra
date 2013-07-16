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
    template: _.template_braces($("#templ-login-ranking").html())
    initialize: ->
      @model = new LoginRankingModel()
      @listenTo(@model,"sync",@render)
      @model.fetch()
    render: ->
      @$el.html(@template(data:@model.toJSON()))
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
    
