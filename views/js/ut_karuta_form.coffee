define (require,exports,module) ->
  init: ->
    $("#list_form").on("click", ".update_flag_done", (ev) ->
      item = $(ev.target).closest("[data-item-id]")
      item_id = item.data("item-id")
      name = item.find(".item_name").text()
      date = item.find(".item_date span").map((i,e)->$(e).text()).toArray().join(" ")
      console.log(date)
      if confirm("#{name} @ [#{date}] のフォームを返信済みにしてよろしいですか？")
        $.post("/api/ut_karuta/update_flag/done/" + item_id, -> location.reload())
      false
    )
    $("#list_form").on("click", ".update_flag_cancel", (ev) ->
      item_id = $(ev.target).closest("[data-item-id]").data("item-id")
      $.post("/api/ut_karuta/update_flag/cancel/" + item_id, -> location.reload())
    )
