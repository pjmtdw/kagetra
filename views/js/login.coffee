define [ "crypto-hmac", "crypto-base64", "crypto-pbkdf2"], ->
  UserListModel = Backbone.Model.extend
    urlRoot: "api/user/auth/list"

  data_to_option = (data) ->
    ("<option value='#{a}'>#{b}</option>" for [a,b] in data).join()

  UserListView = Backbone.View.extend
    initialize: ->
      @model = new UserListModel()
      @$el.html($("#templ-user-list").html())
      @listenTo(@model,"sync",@render)
    events:
      "change #initials": "sync_initials"
    sync_initials: ->
      @model.set("id",$("#initials").val())
      @model.fetch()
    render: ->
      $("#user-names").html(data_to_option(@model.get("list")))


  SharedPasswdView = Backbone.View.extend
    el: "#container-shared-pass"
    events:
      "submit #shared-pass" : "on_shared_pass_submit"
    initialize: -> @render()
    render: ->
      @$el.html($("#templ-shared-pass").html())
      $("#shared-pass input[type=password]").focus()

    on_shared_pass_submit: _.wrap_submit ->
      return if @submitting
      @submitting = true
      that = this
      elem = $("#shared-pass input[type=password]")
      password = elem.val()
      [hash,msg] = _.hmac_password(password ,g_shared_salt)
      $.post 'api/user/auth/shared',
        hash: hash
        msg: msg
      .done (data) ->
        if data.result == "OK"
          window.shared_passwd_view.remove()
          new LoginView()
        else
          _.cb_alert("共通パスワードが違います").done(->
             elem.val("")
             elem.focus())
        that.submitting = false
      .fail ->
        that.submitting = false
        _.cb_alert('サーバエラー')

  LoginView = Backbone.View.extend
    el: "#container-login"
    events:
      "submit #login": "on_login_submit"

    initialize: -> @render()
    render: ->
      @$el.html($("#templ-login").html())
      if @options.single_mode
        $("#user-list").html($("#templ-user-name").html())
      else
        v = new UserListView()
        $("#user-list").append(v.$el)
        $("#initials").trigger("change")
      $("#login input[type=password]").focus()

    on_login_submit: _.wrap_submit ->
      return if @submitting
      @submitting = true
      that = this
      user_id =
        if @options.single_mode
          $("#login-uid").val()
        else
          $("#user-names").val()
      elem = $("#login input[type=password]")
      password = elem.val()
      first = ->
        $.get "api/user/auth/salt/#{user_id}"
      second = (data) ->
        [hash, msg] = _.hmac_password(password,data.salt)
        $.post 'api/user/auth/user',
          user_id: user_id
          hash: hash
          msg: msg
      $.when(first()).then(second)
      .done (data) ->
        switch data.result
          when "OK"
            window.location.href = "/top"
          when "WRONG_PASSWORD"
            _.cb_alert("個人パスワードが違います").done(->
              elem.val("")
              elem.focus()
            )
          when "NOT_LOGINABLE"
            alert("ログイン権限がありません")
        that.submitting = false
      .fail ->
        that.submitting = false
        _.cb_alert('サーバエラー')
  init: ->
    if $("#templ-user-name").length == 0
      window.shared_passwd_view = new SharedPasswdView()
    else
      window.login_view = new LoginView(single_mode:true)

