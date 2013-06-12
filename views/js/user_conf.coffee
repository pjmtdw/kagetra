define ->
  UserConfModel = Backbone.Model.extend
    url: "/api/user_conf/etc"
  UserConfView = Backbone.View.extend
    el: "#user-conf"
    template:  _.template_braces($("#templ-user-conf").html())
    events:
      "submit .form" : "do_submit"
    do_submit: ->
      @model.set(@$el.find('.form').serializeObj())
      @model.save().done(-> alert("更新しました"))
      false
    initialize: ->
      _.bindAll(this,"render","do_submit")
      @model = new UserConfModel()
      @model.bind("sync",@render)
      @model.fetch()
    render: ->
      @$el.html(@template(@model.toJSON()))

  ChangePassView = Backbone.View.extend
    el: "#change-pass"
    template:  _.template($("#templ-change-pass").html())
    events:
      "submit .form" : "do_submit"
    do_submit: ->
      alert("hoge")
      false
    initialize: ->
      _.bindAll(this,"do_submit")
      @render()
    render: ->
      @$el.html(@template())
  init: ->
    window.change_pass_view = new ChangePassView()
    window.user_conf_view = new UserConfView()
