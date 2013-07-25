define (require,exports,module) ->
  ResultPromotionModel = Backbone.Model.extend
    url: "api/result_list/promotion"
  ResultPromotionView = Backbone.View.extend
    el: "#result-promotion"
    template: _.template_braces($("#templ-result-promotion").html())
    events:
      "submit .change-attr" : "change_attr"
    change_attr: _.wrap_submit (ev)->
      values = _.values($(ev.currentTarget).serializeObj())
      uid = $(ev.currentTarget).data("user-id")
      obj = {values:values}
      aj = $.ajax("api/user/change_attr/#{uid}",{
        data: JSON.stringify(obj),
        contentType: "application/json",
        type: "POST"
      }).done(->alert("変更しました"))
    initialize: ->
      @model = new ResultPromotionModel()
      @listenTo(@model,"sync",@render)
      @model.fetch()
    render: ->
      @$el.html(@template(data:@model.toJSON()))
  init: ->
    window.result_promotion_view = new ResultPromotionView()
