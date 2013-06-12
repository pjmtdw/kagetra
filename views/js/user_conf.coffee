define ["crypto-hmac", "crypto-base64", "crypto-pbkdf2"], ->
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
      try
        el = @$el
        first = ->
          [hash, msg] = _.hmac_password(el.find(".pass-cur").val(),g_cur_salt)
          $.post '/api/user/confirm_password',
            hash: hash
            msg: msg
        second = (data)->
          defer = $.Deferred()
          if data.result == 'OK'
            if el.find(".pass-new").val().length == 0
              return defer.reject("新パスワードが空白です")
            if el.find(".pass-new").val() != el.find(".pass-retype").val()
              return defer.reject("再確認のパスワードが一致しません")
            hash = _.pbkdf2_password(el.find(".pass-new").val(),g_new_salt)
            $.post '/api/user/change_password',
              hash: hash
              salt: g_new_salt
          else
            defer.reject("現在のパスワードが違います")
        third = (data) ->
          defer = $.Deferred()
          if data.result == 'OK'
            defer.resolve("パスワードを変更しました")
          else
            defer.reject(data)
        $.when(first()).then(second).then(third)
          .done((data) -> alert("成功: " + data))
          .fail((data) -> alert("失敗: " + data);console.log data)
        false
      catch e
        console.log e.message
        alert e.message
        false
    initialize: ->
      _.bindAll(this,"do_submit")
      @render()
    render: ->
      @$el.html(@template())
  init: ->
    window.change_pass_view = new ChangePassView()
    window.user_conf_view = new UserConfView()
