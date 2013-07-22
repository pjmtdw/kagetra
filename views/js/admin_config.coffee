define ["crypto-hmac", "crypto-base64", "crypto-pbkdf2"], ->
  AdminConfigView = Backbone.View.extend
    el: "#admin-common"
    events:
      "submit #change-shared-pass" : "change_shared_pass"
    change_shared_pass: ->
      _.confirm_change_password
        el: $("#change-shared-pass")
        cur: "input[name='old-shared-pass']"
        new_1: "input[name='new-shared-pass-1']"
        new_2: "input[name='new-shared-pass-2']"
        url_confirm: 'api/user/auth/shared'
        url_change: 'api/user/change_shared_password'
        url_salt: 'api/user/shared_salt'

  init: ->
    window.admin_config_view = new AdminConfigView()
