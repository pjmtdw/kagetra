define (require,exports,module) ->
  $rc = require("result_common")
  ResultRecordRouter = Backbone.Router.extend
    routes:
      "" : "start"
      "show/:name(/:params)" : "show"
    start: ->
      @navigate("show/myself",{trigger:true,replace:true})
    change_page: (page)->
      @curparam.page = page
      params = $.param(@curparam)
      @navigate("show/#{@curname}/#{params}",{trigger:true,replace:true})
    change_span: (span)->
      @curparam.span = span
      @curparam.page = 1
      params = $.param(@curparam)
      @navigate("show/#{@curname}/#{params}",{trigger:true,replace:true})
    show: (name,params)->
      if not window.result_record_view?
        window.result_record_view = new ResultRecordView()
      nm = encodeURIComponent(name)
      if @curname != nm
        window.result_record_view.aggr_loaded = false
      @curname = nm
      params = if params then _.deparam(params) else {}
      @curparam = params
      window.result_record_view.search(name,params.span or "recent",params.page or 1)
  ResultRecordView = Backbone.View.extend
    template: _.template_braces($("#templ-record").html())
    template_result: _.template_braces($("#templ-record-result").html())
    template_detail: _.template_braces($("#templ-record-detail").html())
    events:
      "click .page" : "goto_page"
      "click #contest-span .choice" : "change_span"
    goto_page: (ev)->
      obj = $(ev.currentTarget)
      window.result_record_router.change_page(obj.data("page"))
    change_span: (ev)->
      obj = $(ev.currentTarget)
      @aggr_loaded = false
      window.result_record_router.change_span(obj.data("span"))
    initialize: ->
      @aggr_loaded = false
      @render()
    render: ->
      @$el.html(@template())
      @$el.appendTo("#result-record")
    render_result: (data:data) ->
      if not @aggr_loaded
        $("#record-result").html(@template_result(data:data))
        $("#contest-span .choice[data-span='#{data.span}']").addClass("active")
      @aggr_loaded = true
      $("#record-detail").html(@template_detail(data:data))
    search: (name,span,page)->
      that = this
      obj = {
        name: name
        page: parseInt(page)
        no_aggr: @aggr_loaded
        span: span
      }
      aj = $.ajax("api/result_misc/record",{
        data: JSON.stringify(obj),
        contentType: "application/json",
        type: "POST"
      }).done((data)->
        that.render_result(data:data)
      )

  init: ->
    $rc.init()
    window.result_record_router = new ResultRecordRouter()
    Backbone.history.start()
