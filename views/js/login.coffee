define [ "crypto-hmac", "crypto-base64", "crypto-pbkdf2"], ->
  UserListModel = Backbone.Model.extend
    urlRoot: "/api/user/auth/list"

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
    render: -> @$el.html($("#templ-shared-pass").html())

    on_shared_pass_submit: _.wrap_submit ->
      password = $("#shared-pass input[type=password]").val()
      [hash,msg] = _.hmac_password(password ,g_shared_salt)
      $.post '/api/user/auth/shared',
        hash: hash
        msg: msg
      .done (data) ->
        if data.result == "OK"
          window.shared_passwd_view.remove()
          new LoginView()
        else
          alert("パスワードが違います")

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

    on_login_submit: _.wrap_submit ->
      user_id =
        if @options.single_mode
          $("#login-uid").val()
        else
          $("#user-names").val()
      password = $("#login input[type=password]").val()
      first = ->
        $.get "/api/user/auth/salt/#{user_id}"
      second = (data) ->
        [hash, msg] = _.hmac_password(password,data.salt)
        $.post '/api/user/auth/user',
          user_id: user_id
          hash: hash
          msg: msg
      $.when(first()).then(second).done (data) ->
        if data.result == "OK"
          window.location.href = "/top"
        else
          alert("パスワードが違います")
  init: ->
    if $("#templ-user-name").length == 0
      window.shared_passwd_view = new SharedPasswdView()
    else
      window.login_view = new LoginView(single_mode:true)

