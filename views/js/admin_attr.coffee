define ->
  AdminAttrModel = Backbone.Model.extend
    url: "/api/admin/attrs"
  AdminAttrView = Backbone.View.extend
    template: _.template_braces($("#templ-admin-attr").html())
    template_table: _.template_braces($("#templ-attr-table").html())
    template_row: _.template_braces($("#templ-attr-row").html())
    template: _.template_braces($("#templ-admin-attr").html())
    events:
      "click .thead" : "key_click"
      "click [data-value-id]" : "value_click"
      "click .delete-value" : "delete_value"
      "click .delete-key" : "delete_key"
      "click .set-default-value" : "set_default_vaule"
      "click .add-value" : "add_value"
      "click .add-key" : "add_key"
      "click .apply-edit" : "apply_edit"
    apply_edit: (ev) ->
      return if @is_applying
      @is_applying = true
      button = $(".apply-edit")
      button.toggleBtnText()
      ar = $.makeArray($("[data-key-id]").map(->
        {
          key_id:$(@).data("key-id")
          deleted: $(@).hasClass("deleted")
          name: $(@).find(".key-name").text()
          list:$.makeArray($(@).find("[data-value-id]").map(->
           {
             value_id:$(@).data("value-id")
             value: $(@).find(".value-name").text()
             default:$(@).hasClass("default")
             deleted:$(@).hasClass("deleted")
           }))}
      ))
      that = this
      $.ajax("api/admin/update_attr",
        data: JSON.stringify(list:ar)
        contentType: "application/json"
        type: "POST")
      .done(->
        alert("編集しました")
        button.toggleBtnText()
        that.is_applying = false
        that.model.fetch()
      )

    add_key: (ev) ->
      if r = prompt("属性追加","")
        t = @template_table(data:{id:"new",name:r})
        $("#after-last-key").before(t)
        alert("一番最後に追加しました")
    add_value: (ev)->
      if r = prompt("属性追加","")
        t = @template_row(data:{id:"new",value:r})
        $(ev.currentTarget).closest("table").find(".after-last-value").before(t)

    delete_value: (ev)->
      o = $(ev.currentTarget).closest("[data-value-id]")
      o.addClass("deleted")
      o.hide()
    delete_key: (ev)->
      o = $(ev.currentTarget).closest("[data-key-id]")
      o.addClass("deleted")
      o.hide()
    set_default_vaule: (ev)->
      cur = $(ev.currentTarget).closest("[data-value-id]")
      $(ev.currentTarget).closest("[data-key-id]").find(".default").removeClass("default")
      $(ev.currentTarget).closest("[data-key-id]").find(".show-value-button").text("")
      cur.find(".show-value-button").text("○")
      cur.addClass("default")

    key_click: (ev)->
      if @mode == "value"
        return
      table = $(ev.currentTarget).closest("table")
      if _.isNull(@move_from)
        @move_from = table
        table.addClass("key-mark")
        @mode = "key"
        $(ev.currentTarget).find(".show-key-button").append($("<button>",{text:"削除",class:"tiny alert delete-key"}))
      else
        @move_from.find(".show-key-button button").remove()
        _.swap_elem(@move_from,table)
        @move_from = null
        $(".key-mark").removeClass("key-mark")
        @mode = null

    value_click: (ev)->
      if @mode == "key"
        @key_click(ev)
        return
      if _.isNull(@move_from_tr)
        @mode = "value"
        @move_from_tr = $(ev.currentTarget)
        @move_from_tr.addClass("value-mark")
        $(ev.currentTarget).find(".show-value-button").append($("<button>",{text:"デフォルト",class:"tiny set-default-value"}))
        $(ev.currentTarget).find(".show-value-button").append($("<button>",{text:"削除",class:"tiny alert delete-value"}))
      else
        @move_from_tr.find(".show-value-button button").remove()
        table = $(ev.currentTarget).closest("table")
        return if @move_from_tr.closest("table").data("key-id") != table.data("key-id")
        $(".value-mark").removeClass("value-mark")
        _.swap_elem(@move_from_tr,$(ev.currentTarget))
        @move_from_tr = null
        @mode = null
    initialize: ->
      @move_from = null
      @move_from_tr = null
      @model = new AdminAttrModel()
      @listenTo(@model,"sync",@render)
      @model.fetch()
    render: ->
      @$el.html(@template(data:@model.toJSON()))
      @$el.appendTo("#admin-attr")
  init: ->
    window.admin_attr_view = new AdminAttrView()
