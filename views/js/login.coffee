define [ "crypto-hmac", "crypto-base64", "crypto-pbkdf2"], ->
  UserListModel = Backbone.Model.extend
    urlRoot: "/api/user/list"

  UserListView = Backbone.View.extend
    el: "#login"
    initialize: -> this.render()
    events:
      "change #initials": "render"
    render: ->
      this.model.set id:$("#initials").val()
      this.model.fetch
        success: (data) ->
          $("#names").html data_to_option(data.toJSON().list)

  data_to_option = (data) ->
    ("<option value='#{a}'>#{b}</option>" for [a,b] in data).join()

  hash_password = (pass,salt) ->
    pbk = CryptoJS.PBKDF2(pass,salt, {keySize: 256/32, iterations: 100})
    secret = pbk.toString(CryptoJS.enc.Base64)
    hmac = CryptoJS.algo.HMAC.create(CryptoJS.algo.SHA256, secret)
    msg = CryptoJS.lib.WordArray.random(128/8).toString(CryptoJS.enc.Base64)
    hmac.update(msg)
    hash = hmac.finalize().toString(CryptoJS.enc.Base64)
    [hash, msg]

  on_shared_pass_submit = ->
    password = $("#shared-pass input[type=password]").val()
    [hash,msg] = hash_password(password ,g_shared_salt)
    $.post '/api/user/auth_shared',
      hash: hash
      msg: msg
    .done (data) ->
      if data.result == "OK"
        $("#shared-pass").addClass("hide")
        $("#login").removeClass("hide")
        new UserListView({model: new UserListModel()})
      else
        alert("パスワードが違います")

  on_login_submit = ->
    user_id = $("#names").val()
    password = $("#login input[type=password]").val()
    first = ->
      $.get "/api/user/auth_salt/#{user_id}"
    second = (data) ->
      [hash, msg] = hash_password(password,data.salt)
      $.post '/api/user/auth_user',
        user_id: user_id
        hash: hash
        msg: msg
    $.when(first()).then(second).done (data) ->
      if data.result == "OK"
        window.location.href = "/top"
      else
        alert("パスワードが違います")
  init: ->
    $("#login").submit(_.wrap_submit(on_login_submit))
    $("#shared-pass").submit(_.wrap_submit(on_shared_pass_submit))
    $("#shared-pass input[type=password]").focus()
