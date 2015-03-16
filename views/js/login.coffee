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
  
  BoardMessageModel = Backbone.Model.extend
    # Eメールアドレス変換をかけるために /public/ でアクセスする
    url: -> (if @get('mode') == "shared" then "/public" else "") + "/api/board_message/#{@get('mode')}"

  BoardMessageView = Backbone.View.extend
    el: "#container-board-message"
    template: _.template_braces($("#templ-board-message").html())
    initialize: ->
      @model = new BoardMessageModel(mode:@options.mode)
      @listenTo(@model,"sync",@render)
      @model.fetch()
    render: ->
      data = @model.toJSON()
      if data.message
        @$el.html(@template(data:data))
      else
        @$el.empty()
    change_mode: (mode) ->
      @model.set("mode",mode)
      @model.fetch()

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
          window.board_message_view.change_mode("user")
        else
          message = "共通パスワードが違います．"
          try
            d = Date.parse(data.updated_at)
            dt = Math.floor(((new Date()).getTime() - d) / 3600000)
            if dt < 24
              message += "パスワードは#{dt}時間前に変更されました"
            else if dt < 90*24
              message += "パスワードは#{Math.floor(dt/24)}日前に変更されました"
          catch e
            console.log(e)
          _.cb_alert(message).always(->
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
      that = this
      user_id =
        if @options.single_mode
          $("#login-uid").val()
        else
          $("#user-names").val()
      if _.isEmpty(user_id)
        _.cb_alert("ログインユーザを選択して下さい")
        return
      @submitting = true
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
            _.cb_alert("個人パスワードが違います").always(->
              elem.val("")
              elem.focus()
            )
          when "COOKIE_BLOCKED"
            _.cb_alert("Cookieが無効化もしくはブロックされています．ブラウザの設定を確認して下さい．")
          when "NOT_LOGINABLE"
            _.cb_alert("ログイン権限がありません")
        that.submitting = false
      .fail ->
        that.submitting = false
        _.cb_alert('サーバエラー')
  init: ->
    if $("#templ-user-name").length == 0
      window.shared_passwd_view = new SharedPasswdView()
      window.board_message_view = new BoardMessageView(mode:"shared")
    else
      window.login_view = new LoginView(single_mode:true)
      window.board_message_view = new BoardMessageView(mode:"user")

