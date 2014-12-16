define (require,exports,module) ->
  $rc = require("result_common")
  _.mixin
    show_promotion_event: (x)->
      s = x.event_date
      if x.event_name
        s += " ( <a href='result#contest/#{x.event_id}'>#{_.escape(x.event_name)}</a> #{_.escape(x.prize)} )"
      s

  ResultPromotionRouter = Backbone.Router.extend
  class ResultPromotionRouter extends _.router_base("result_promotion",["recent","ranking"])
    routes:
      "recent" : "recent"
      "ranking(/:params)" : "ranking"
      "" : -> @navigate("recent", {trigger:true, replace:true})
    switch_nav: (mode)->
      $("#promotion-nav [data-mode]").removeClass("active")
      $("#promotion-nav [data-mode='#{mode}']").addClass("active")

    recent: ->
      @switch_nav("recent")
      @remove_all("recent")
      if not window.result_promotion_recent_view
        window.result_promotion_recent_view = new ResultPromotionRecentView()
    ranking: (params)->
      @switch_nav("ranking")
      @remove_all("ranking")
      if not window.result_promotion_ranking_view
        window.result_promotion_ranking_view = new ResultPromotionRankingView()
      if not params
        params = "from=debut&to=prom_a&mode=days"
      window.result_promotion_ranking_view.refresh(params)

  ResultPromotionRecentModel = Backbone.Model.extend
    url: "api/result_promotion/recent"
  ResultPromotionRecentView = Backbone.View.extend
    template: _.template_braces($("#templ-result-promotion-recent").html())
    events:
      "submit .change-attr" : "change_attr"
    change_attr: _.wrap_submit (ev)->
      values = _.values($(ev.currentTarget).serializeObj())
      uid = $(ev.currentTarget).data("user-id")
      eid = $(ev.currentTarget).data("event-id")
      obj = {values:values}
      aj = $.ajax("api/user/change_attr/#{eid}/#{uid}",{
        data: JSON.stringify(obj),
        contentType: "application/json",
        type: "POST"
      }).done(_.with_error("変更しました"))
    initialize: ->
      @model = new ResultPromotionRecentModel()
      @listenTo(@model,"sync",@render)
      @model.fetch()
    render: ->
      @$el.html(@template(data:@model.toJSON()))
      @$el.appendTo("#result-promotion-recent")
  ResultPromotionRankingModel = Backbone.Model.extend
    url: "api/result_promotion/ranking"
  ResultPromotionRankingView = Backbone.View.extend
    template: _.template_braces($("#templ-result-promotion-ranking").html())
    template_body: _.template_braces($("#templ-result-promotion-ranking-body").html())
    template_a_champ: _.template_braces($("#templ-result-promotion-ranking-a-champ").html())
    events:
      "change #promotion-ranking-form select" : ->
        window.result_promotion_router.navigate("ranking/"+$.param($("#promotion-ranking-form").serializeObj()),trigger:true)
    initialize: ->
      @$el.html(@template())
      @$el.appendTo("#result-promotion-ranking")
      @model = new ResultPromotionRankingModel()
      @listenTo(@model,"sync",@render)
    refresh: (params)->
      obj = _.deparam(params)
      $("#promotion-ranking-form").fillForm(obj)
      @model.fetch({data:obj})
    render: ->
      tmpl = if @model.get('display') == 'a_champ' then @template_a_champ else @template_body
      $("#promotion-ranking-body").html(tmpl(data:@model.toJSON()))
  init: ->
    $rc.init()
    window.result_promotion_router = new ResultPromotionRouter()
    Backbone.history.start()
