define ->
  AdminAttrView = Backbone.View.extend
    template: _.template_braces($("#attr-key-values").html())
    events:
      "change .attr-key-names" : "do_key_change"
    do_key_change: ->
      kid = @$el.find(".attr-key-names").val()
      kv = @$el.find(".attr-value-names")
      kv.empty()
      for i in @collection.key_values[kid]
        v = @collection.attr_values[i].value
        kv.append("<option value='#{i}'>#{v}</option>")
      kv.trigger("change")
    render: ->
      @$el.html(@template(key_names:@collection.key_names))
      @$el.find(".attr-key-names").trigger("change")
  AdminModel = Backbone.Model.extend
    defaults:
      "visible": true
  AdminCollection = Backbone.Collection.extend
    model: AdminModel
    url: "/api/admin/list"
    initialize: ->
      @sort_keys = [["furigana",1]]
    parse: (data) ->
      @attr_values = data.attr_values
      @key_names = data.key_names
      @key_values = data.key_values
      data.list
    # default_order: 1=asc, -1=desc
    add_comp_sort: (key,default_order) ->
      lst = _.last(@sort_keys)
      if lst[0] == key
        @sort_keys.pop()
        @sort_keys.push([key,-lst[1]])
      else
        @sort_keys.push([key,default_order])
      @sort_keys = @sort_keys[-4..-1] # only sort keys by last four
      that = this
      fs = (k) ->
        mp = {
          login_latest: (x) -> x.get("login_latest") || "0000_01_01"
          furigana: (x) -> x.get("furigana")
        }
        if mp[k]
          return mp[k]
        if k.indexOf("attr-key:") == 0
          kindex = parseInt(k["attr-key:".length..-1])
          return (x) ->
            attrs=x.get('attrs')
            if not attrs then return -1
            that.attr_values[attrs[kindex]].index
      gs = ([fs(x),y] for [x,y] in @sort_keys)
      gs.reverse()
      h = (q,x,y) ->
        sign=q[1];qx=q[0](x);qy=q[0](y)
        if qx>qy then sign else if qx<qy then -sign else 0
      @comparator = (x,y) ->
        r = 0
        for g in gs
          z = h(g,x,y)
          if z != 0
            r = z
            break
        r
      @sort()
  AdminView = Backbone.View.extend
    el: "#admin-view"
    template_header: _.template_braces($("#templ-admin-header").html())
    template_body: _.template_braces($("#templ-admin-body").html())
    events:
      "submit #filter-form": "do_submit"
      "click .select-user" : "do_select_user"
      "click #reveal-edit" : "do_reveal_edit"
      "change .attr-value-names" : "do_submit"
      "click .thead-last-login" : -> @collection.add_comp_sort("login_latest",-1)
      "click .thead-furigana" : -> @collection.add_comp_sort("furigana",1)
      "click .thead-key-name" : "do_sort_attr"
      "click #clear-select" : "do_clear_select"
    do_clear_select: ->
      for m in @collection.models
        m.set("selected",false)
      $(".selected").removeClass("selected")
      $("#selected-count").text(0)

    do_sort_attr: (ev)->
      kindex = $(ev.currentTarget).attr("data-key-index")
      @collection.add_comp_sort("attr-key:#{kindex}",1)

    apply_filter: ->
      f_name = $("#filter-text").val()
      f_attr = parseInt(@$el.find(".attr-value-names").val())
      console.log f_attr
      for m in @collection.models
        # name filter
        name = m.get("name")
        furigana = m.get("furigana")
        v1 = _.every(f_name.split(" "),(x)-> "#{name} #{furigana}".indexOf(x) >= 0)
        # attr filter
        attrs = m.get("attrs")
        v2 = attrs and attrs.indexOf(f_attr) >= 0
        m.set("visible",v1 and v2)

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
      @listenTo(@collection,"sync",@.render_all)
      @listenTo(@collection,"sort",@.render_body)
      @collection.fetch()
    render_all: ->
      @render_header()
      @render_body()
    render_body: ->
      @$el.find(".body").html(@template_body(
        data:@collection.toJSON()
        attr_values: @collection.attr_values
        key_names: @collection.key_names
      ))
    render_header: ->
      @$el.find(".header").html(@template_header(
        key_names: @collection.key_names
      ))
      aview = new AdminAttrView(collection:@collection)
      aview.render()
      @$el.find(".attr-key-values").append(aview.$el)

  AdminEditView = Backbone.View.extend
    el: "#admin-edit"
    events:
      "click #add-permission": (ev) -> @change_permission(ev,"add")
      "click #del-permission": (ev) -> @change_permission(ev,"del")
      "click #change-attr": "change_attr"
    get_uids: ->
      return (x.get("id") for x in @collection.models when x.get("selected"))
    change_attr: (ev)->
      uids = @get_uids()
      $.ajax("/api/admin/change_attr",
        data: JSON.stringify(
                uids: uids
                value: @$el.find(".attr-value-names").val())
        contentType: "application/json"
        type: "POST").done( -> alert("更新完了"))
      
    change_permission: (ev,mode) ->
      obj = $(ev.currentTarget)
      uids = @get_uids()
      $.ajax("/api/admin/permission",
        data: JSON.stringify(
                mode: mode
                uids: uids
                type: $("#permission-name").val())
        contentType: "application/json"
        type: "POST").done( -> alert("更新完了"))
      
    template: _.template($("#templ-admin-edit").html())
    render: ->
      @$el.html(@template(data:@collection.toJSON()))
      view = new AdminAttrView(collection:@collection)
      view.render()
      @$el.find(".attr-key-values").append(view.$el)
    reveal: ->
      @$el.foundation("reveal","open")
      @render()

  init: ->
    collection = new AdminCollection()
    window.admin_view = new AdminView(collection: collection)
    window.admin_edit_view = new AdminEditView(collection: collection)
