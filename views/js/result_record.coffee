define (require,exports,module) ->
  $rc = require("result_common")
  ResultRecordRouter = Backbone.Router.extend
    routes:
      "" : "start"
      "show/:name" : "show"
    start: ->
      @navigate("show/myself",{trigger:true,replace:true})
    show: (name)->
      name = decodeURIComponent(name)
      if not window.result_record_view?
        window.result_record_view = new ResultRecordView()
      window.result_record_view.search(name)
  ResultRecordView = Backbone.View.extend
    template: _.template_braces($("#templ-record").html())
    template_result: _.template_braces($("#templ-record-result").html())
    initialize: ->
      @render()
    render: ->
      @$el.html(@template())
      @$el.appendTo("#result-record")
    render_result: (data:data) ->
      $("#record-result").html(@template_result(data:data))
    #do_search: _.wrap_submit ->
    #  obj = $("#record-form").serializeObj()
    #  window.result_record_router.navigate("show/#{$.param(obj)}",{trigger:true})
    search: (name)->
      that = this
      obj = {
        name: name
      }
      aj = $.ajax("api/result_misc/record",{
        data: JSON.stringify(obj),
        contentType: "application/json",
        type: "POST"
      }).done((data)->that.render_result(data:data))

  init: ->
    $rc.init()
    window.result_record_router = new ResultRecordRouter()
    Backbone.history.start()
