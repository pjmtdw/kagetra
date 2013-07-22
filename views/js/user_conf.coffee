define ["crypto-hmac", "crypto-base64", "crypto-pbkdf2"], ->
  UserConfModel = Backbone.Model.extend
    url: "api/user_conf/etc"
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
      @listenTo(@model,"sync",@render)
      @model.fetch()
    render: ->
      @$el.html(@template(@model.toJSON()))

  ChangePassView = Backbone.View.extend
    el: "#change-pass"
    template:  _.template($("#templ-change-pass").html())
    events:
      "submit .form" : "do_submit"
    do_submit: ->
      _.confirm_change_password
        el: @$el
        cur: ".pass-cur"
        new_1: ".pass-new"
        new_2: ".pass-retype"
        url_confirm: 'api/user/confirm_password'
        url_change: 'api/user/change_password'
        url_salt: 'api/user/mysalt'

    initialize: ->
      _.bindAll(this,"do_submit")
      @render()
    render: ->
      @$el.html(@template())
  init: ->
    window.change_pass_view = new ChangePassView()
    window.user_conf_view = new UserConfView()
