define ->
  AdminModel = Backbone.Model.extend
    defaults:
      "visible": true
  AdminCollection = Backbone.Collection.extend
    model: AdminModel
    url: "/api/admin/list"
    parse: (data) ->
      @value_names = data.value_names
      @key_names = data.key_names
      @key_values = data.key_values
      data.list
  AdminView = Backbone.View.extend
    el: "#admin-view"
    template_header: _.template_braces($("#templ-admin-header").html())
    template_body: _.template_braces($("#templ-admin-body").html())
    events:
      "submit #filter-form": "do_submit"
      "click .select-user" : "do_select_user"
      "click #reveal-edit" : "do_reveal_edit"
      "change #attr-key-names" : "do_key_change"
      "change #attr-key-values" : "do_submit"
    apply_filter: ->
      f_name = $("#filter-text").val()
      f_attr = parseInt($("#attr-key-values").val())
      for m in @collection.models
        # name filter
        name = m.get("name")
        furigana = m.get("furigana")
        v1 = _.every(f_name.split(" "),(x)-> "#{name} #{furigana}".indexOf(x) >= 0)
        # attr filter
        attrs = m.get("attrs")
        v2 = attrs and attrs.indexOf(f_attr) >= 0
        m.set("visible",v1 and v2)

    do_key_change: ->
      kid = $("#attr-key-names").val()
      $("#attr-key-values").empty()
      for i in @collection.key_values[kid]
        v = @collection.value_names[i]
        $("#attr-key-values").append("<option value='#{i}'>#{v}</option>")
      $("#attr-key-values").trigger("change")
    do_reveal_edit: ->
      if parseInt($("#selected-count").text()) == 0
        alert("編集対象をチェックして下さい")
      else
        window.admin_edit_view.reveal()
    do_select_user: (ev)->
      obj = $(ev.currentTarget)
      uid = parseInt(obj.attr("data-user-id"))
      select = not obj.hasClass("selected")
      obj.toggleClass("selected")
      count = 0
      for m in @collection.models
        if uid == -1
          m.set("selected",select) if m.get("visible")
          cid = m.get("id")
          $(".select-user[data-user-id='#{cid}']")
            .toggleClass("selected",select)
        else
          m.set("selected",select) if uid == m.get("id")

        if m.get("selected") then count += 1
      $("#selected-count").text(count)
    do_submit: ->
      @apply_filter()
      @render_body()
      false
    initialize: ->
      _.bindAll(this,"render_all","do_submit","do_select_user","do_key_change")
      this.listenTo(@collection,"sync",@.render_all)
      @collection.fetch()
    render_all: ->
      @render_header()
      @render_body()
    render_body: ->
      @$el.find(".body").html(@template_body(
        data:@collection.toJSON()
        value_names: @collection.value_names
        key_names: @collection.key_names
      ))
    render_header: ->
      @$el.find(".header").html(@template_header(
        key_names: @collection.key_names
      ))
      $("#attr-key-names").trigger("change")

  AdminEditView = Backbone.View.extend
    el: "#admin-edit"
    events:
      "click #add-permission": (ev) -> @change_permission(ev,"add")
      "click #del-permission": (ev) -> @change_permission(ev,"del")
    change_permission: (ev,mode) ->
      obj = $(ev.currentTarget)
      uids = (x.get("id") for x in @collection.models when x.get("selected"))
      $.ajax("/api/admin/permission",
        data: JSON.stringify(
                mode: mode
                uids: uids
                type: $("#permission-name").val())
        contentType: "application/json"
        type: "POST").done( -> alert("更新完了"))
      
    template: _.template($("#templ-admin-edit").html())
    initialize: ->
      _.bindAll(this,"change_permission")
    render: ->
      @$el.html(@template(data:@collection.toJSON()))
    reveal: ->
      @$el.foundation("reveal","open")
      @render()

  init: ->
    collection = new AdminCollection()
    window.admin_view = new AdminView(collection: collection)
    window.admin_edit_view = new AdminEditView(collection: collection)
