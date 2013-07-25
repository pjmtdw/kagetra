define (require,exports,module) ->
  ResultRankingRouter = Backbone.Router.extend
    routes:
      "" : "start"
      "show/:params" : "show"
    start: ->
      dt = new Date()
      params = $.param({
        start: "#{dt.getFullYear()-1}-#{1+dt.getMonth()}"
        end: "#{dt.getFullYear()}-#{1+dt.getMonth()}"
        key1: "win"
        key2: "contest_num"
        filter: "official"
      })
      @navigate("show/#{params}",{trigger:true,replace:true})
    show: (params) ->
      if not window.result_ranking_view?
        window.result_ranking_view = new ResultRankingView()
      obj = _.deparam(params)
      window.result_ranking_view.search(obj)
      $("#ranking-form").fillForm(obj)

  ResultRankingView = Backbone.View.extend
    template: _.template_braces($("#templ-ranking").html())
    template_result: _.template_braces($("#templ-ranking-result").html())
    events:
      "submit #ranking-form" : "do_search"
      "change #ranking-form select" : -> $("#ranking-form").submit()
      "click .goto-year" : "goto_year"
    initialize: ->
      @render()
    render: ->
      @$el.html(@template())
      @$el.appendTo("#result-ranking")
    render_result: (data:data) ->
      $("#ranking-result").html(@template_result(data:data))
    do_search: _.wrap_submit ->
      obj = $("#ranking-form").serializeObj()
      window.result_ranking_router.navigate("show/#{$.param(obj)}",{trigger:true})
    goto_year: (ev)->
      year = $(ev.currentTarget).data("year")
      $("#ranking-form input[name='start']").val("#{year}-1")
      $("#ranking-form input[name='end']").val("#{year}-12")
      $("#ranking-form").submit()
      # TDOO: is this the correct way to close dropdown ?
      $("[data-dropdown='year-list']").click()
    search: (obj)->
      that = this
      aj = $.ajax("api/result_ranking/search",{
        data: JSON.stringify(obj),
        contentType: "application/json",
        type: "POST"
      }).done((data)->that.render_result(data:data))

  init: ->
    window.result_ranking_router = new ResultRankingRouter()
    Backbone.history.start()
