data_to_option = (data) ->
  ("<option value='#{a}'>#{b}</option>" for [a,b] in data).join()
on_initials_change = ->
  code = $("#initials").val()
  console.log(code)
  $.ajax "/user/list/#{code}",
    success: (data)->
      $("#names").html data_to_option(data)
$(document).ready ->
  $("#initials").change(on_initials_change)
  $.ajax '/user/initials',
    success: (data)->
      $("#initials").html data_to_option(data)
      on_initials_change()
