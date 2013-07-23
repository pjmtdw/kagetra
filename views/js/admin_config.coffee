define ["crypto-aes", "crypto-hmac", "crypto-base64", "crypto-pbkdf2"], ->
  AdminConfigView = Backbone.View.extend
    el: "#admin-common"
    events:
      "submit #change-shared-pass" : "change_shared_pass"
      "submit #change-addrbook-pass" : "change_addrbook_pass"
    change_shared_pass: ->
      _.confirm_change_password
        el: $("#change-shared-pass")
        cur: "input[name='old-shared-pass']"
        new_1: "input[name='new-shared-pass-1']"
        new_2: "input[name='new-shared-pass-2']"
        url_confirm: 'api/user/auth/shared'
        url_change: 'api/user/change_shared_password'
        url_salt: 'api/user/shared_salt'
    change_addrbook_pass: _.wrap_submit ->
      fel = $("#change-addrbook-pass")
      cpass = fel.find("input[name='old-addrbook-pass']").val()
      npass1 = fel.find("input[name='new-addrbook-pass-1']").val()
      npass2 = fel.find("input[name='new-addrbook-pass-2']").val()
      
      if not g_addrbook_check_password(cpass)
        alert('旧パスワードが間違っています')
        return
      else if npass1.length == 0
        alert('新パスワードが空白です')
        return
      else if npass1 != npass2
        alert('確認用パスワードが一致しません')
        return

      # TODO: パスワードを平文で送るのは危険
      aj = $.ajax("api/addrbook/change_pass",
        data: JSON.stringify(
          cur_password: cpass
          new_password: npass1
          )
        contentType: "application/json"
        type: "POST").done(-> alert("完了"))
      
      

  init: ->
    window.admin_config_view = new AdminConfigView()
