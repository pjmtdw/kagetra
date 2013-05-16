data_to_option = (data) ->
  ("<option value='#{a}'>#{b}</option>" for [a,b] in data).join()
on_initials_change = ->
  code = $("#initials").val()
  $.ajax "/user/list/#{code}",
    success: (data)->
      $("#names").html data_to_option(data)

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


$(document).ready ->
  $(document).foundation()
  $("#initials").change(on_initials_change)
  $("#main-form").submit(on_main_form_submit)
