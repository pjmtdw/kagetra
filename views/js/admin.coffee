define ->
  AdminModel = Backbone.Model.extend
    defaults:
      "visible": true
  AdminCollection = Backbone.Collection.extend
    model: AdminModel
    url: "/api/admin/list"
  AdminView = Backbone.View.extend
    el: "#admin-view"
    template: _.template_braces($("#templ-admin-view").html())
    events:
      "submit #filter-form": "do_filter"
      "click .select-user" : "do_select_user"
      "click #reveal-edit" : "do_reveal_edit"
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
    do_filter: ->
      filter = $("#filter-text").val()
      for m in @collection.models
        name = m.get("name")
        furigana = m.get("furigana")
        visible = _.every(filter.split(" "),(x)-> "#{name} #{furigana}".indexOf(x) >= 0)
        m.set("visible",visible)
      @render()
      false
    initialize: ->
      _.bindAll(this,"do_filter","do_select_user")
      @collection.bind("sync",@.render,this)
      @collection.fetch()
    render: ->
      @$el.html(@template(filter_text:$("#filter-text").val(),data:@collection.toJSON()))

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
