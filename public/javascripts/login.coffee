define ["crypto","jquery"], (CryptoJS,$) ->
  data_to_option = (data) ->
    ("<option value='#{a}'>#{b}</option>" for [a,b] in data).join()
  on_initials_change = ->
    code = $("#initials").val()
    $.ajax "/user/list/#{code}",
      success: (data)->
        $("#names").html data_to_option(data)

  on_shared_pass_submit = ->
    p = $("#shared-pass input[type=password]").val()
    k = CryptoJS.PBKDF2(p,g_shared_salt, {keySize: 256/32, iterations: 100})
    secret = k.toString(CryptoJS.enc.Base64)
    hmac = CryptoJS.algo.HMAC.create(CryptoJS.algo.SHA256, secret)
    hmac.update(g_shared_rand)
    hash = hmac.finalize().toString(CryptoJS.enc.Base64)

    $.ajax '/user/auth_shared',
      type: 'POST'
      data:
        hash: hash
        rand: g_shared_rand
      success: (data) ->
        alert(data.result)
    false

  on_main_form_submit = ->
    $.ajax '/user/auth',
      type: 'POST'
      data:
        user_id: $("#names").val()
        password: $("#main-form input[type=password]").val()
      success: (data) ->
        if data.result == "OK"
          window.location.replace("/top")
        else
          alert("Authentication Failed")
    false
  ->
    $(document).ready ->
      $(document).foundation()
      $("#initials").change(on_initials_change)
      $("#main-form").submit(on_main_form_submit)
      $("#shared-pass").submit(on_shared_pass_submit)
