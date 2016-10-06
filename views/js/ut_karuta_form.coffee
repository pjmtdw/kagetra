define (require,exports,module) ->
  init: ->
    $("#list_form").on("click", ".update_status", (ev) ->
      tgt = $(ev.target)
      item = tgt.closest("[data-item-id]")
      item_id = item.data("item-id")
      name = item.find(".item_name").text()
      date = item.find(".item_date").text()
      status = tgt.data("status")
      haveto_confirm = status != "notyet"
      status_message = if status == "ignore" then "に返信しなくても" else "を返信済みにして"
      if not haveto_confirm or confirm("#{name} @ #{date} #{status_message}よろしいですか？")
        $.post("/api/ut_karuta/update_status/#{item_id}/#{status}", -> location.reload())
      false
    )
