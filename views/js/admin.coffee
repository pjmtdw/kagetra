define ["crypto-hmac", "crypto-base64", "crypto-pbkdf2"], ->
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
    url: "api/admin/list"
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
          loginable: (x) -> if x.get("loginable") then 1 else 0
          permission: (x) -> if x.get("admin") then "zzz" else x.get("permission")
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
      "click .thead-loginable" : -> @collection.add_comp_sort("loginable",-1)
      "click .thead-permission" : -> @collection.add_comp_sort("permission",-1)
      "click .thead-key-name" : "do_sort_attr"
      "click #clear-select" : "do_clear_select"
      "click .furigana" : "start_edit_furigana"
      "click .name" : "start_edit_name"
      "click .user-attr" : "start_edit_attr"
      "submit .edit-item" : "submit_edit_item"
      "click #undo-last-edit" : "undo_last_edit"
      "click #apply-edit" : "apply_edit"
      "click #add-user" : "add_user"
    add_user: ->
      t = "#admin-user-add"
      v = new AdminUserAddView(target:t,collection:@collection)
      _.reveal_view(t,v)
    apply_edit: ->
      if confirm("#{@edit_log.length} 点の変更を反映してもいいですか？")
        elog = JSON.stringify(@edit_log)
        aj = $.ajax("api/admin/apply_edit",
          data: elog
          contentType: "application/json"
          type: "POST")
        aj.done( ->
          alert("反映完了")
          @edit_log = []
          $("#edit-log-count").text(@edit_log.length)
        )
    undo_last_edit: ->
      @edit_log.pop()
      $("#edit-log-count").text(@edit_log.length)

    submit_edit_item: (ev)->
      obj = $(ev.currentTarget)
      input = obj.find("input[type='text']")
      if input.length == 0
        input = obj.find("select")
      if input.length == 0
        return false
      new_val = input.val()
      old_val = input.data("old-value")
      type = obj.data("type")
      if new_val.toString() != old_val.toString()
        @edit_log.push(
          type: type
          uid: obj.data("uid")
          old_val: old_val
          new_val: new_val
        )
        $("#edit-log-count").text(@edit_log.length)
      new_text = if type == "attr" then @collection.attr_values[new_val].value else new_val
      obj.parent().text(new_text)
      false
    start_edit_attr: (ev) ->
      obj = $(ev.currentTarget)
      return if obj.find("form").length > 0
      kid = obj.data("key-id")
      vid = obj.data("value-id")
      uid = obj.parent().data("uid")
      form = $("<form>", {
        class: 'edit-item'
        "data-type": "attr"
        "data-uid":  uid
      })
      select = $("<select>",{
        "data-old-value": vid
      })
      for v in @collection.key_values[kid]
        opt = $("<option>",{
          value: v
          text: @collection.attr_values[v].value
          selected: v == parseInt(vid)
        })
        select.append(opt)
      form.append(select)
      obj.empty()
      obj.append(form)
      select.focus()
      select.one("change",->select.trigger("blur"))
      select.one("blur",->form.submit())

    start_edit_text: (obj,type) ->
      return if obj.find("form").length > 0
      txt = obj.text()
      uid = obj.parent().data("uid")
      input = $("<input>",{
        type: 'text'
        value: txt
        "data-old-value": txt
      })
      form = $("<form>", {
        class: 'edit-item'
        "data-type": type
        "data-uid":  uid
      })
      form.append(input)
      obj.empty()
      obj.append(form)
      input.focus()
      input.one("blur",->form.submit())
    start_edit_name: (ev) ->
      obj = $(ev.currentTarget)
      @start_edit_text(obj,"name")

    start_edit_furigana: (ev) ->
      obj = $(ev.currentTarget)
      @start_edit_text(obj,"furigana")
    do_clear_select: ->
      for m in @collection.models
        m.set("selected",false)
      $(".selected").removeClass("selected")
      $("#selected-count").text(0)

    do_sort_attr: (ev)->
      kindex = $(ev.currentTarget).data("key-index")
      @collection.add_comp_sort("attr-key:#{kindex}",1)

    apply_filter: ->
      f_name = $("#filter-text").val()
      f_attr = parseInt(@$el.find(".attr-value-names").val())
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
      uid = parseInt(obj.parent().data("uid"))
      select = not obj.hasClass("selected")
      obj.toggleClass("selected")
      count = 0
      if uid == -1
        $(".select-user").toggleClass("selected",select)

      for m in @collection.models
        if uid == -1
          m.set("selected",select) if m.get("visible")
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
      @edit_log = []
    render_all: ->
      @render_header()
      @render_body()
    render_body: ->
      r = @collection.toJSON()
      r.edit_log_count = @edit_log.length
      @$el.find(".body").html(@template_body(
        data:r
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
      "submit #change-passwd": "change_passwd"
      "click #delete-user": "delete_user"
    delete_user: _.wrap_submit ->
      return unless (prompt("削除するにはdeleteと入れて下さい","") == "delete")
      uids = @get_uids()
      $.ajax("api/user/delete_users",
        data: JSON.stringify(uids: uids)
        contentType: "application/json"
        type: "DELETE").done( -> alert("削除完了"))
    get_uids: ->
      return (x.get("id") for x in @collection.models when x.get("selected"))
    change_attr: (ev)->
      uids = @get_uids()
      $.ajax("api/admin/change_attr",
        data: JSON.stringify(
                uids: uids
                value: @$el.find(".attr-value-names").val())
        contentType: "application/json"
        type: "POST").done( -> alert("更新完了"))
    change_passwd: (ev)->
      uids = @get_uids()
      el = @$el
      if el.find(".pass-new").val().length == 0
        alert("新パスワードが空白です")
        return false
      if el.find(".pass-new").val() != el.find(".pass-retype").val()
        alert("再確認のパスワードが一致しません")
        return false
      hash = _.pbkdf2_password(el.find(".pass-new").val(),g_new_salt)
      p = $.post 'api/user/change_password',
        hash: hash
        salt: g_new_salt
        uids: uids
      p.done(-> alert("パスワードを変更しました"))
      false

    change_permission: (ev,mode) ->
      obj = $(ev.currentTarget)
      uids = @get_uids()
      $.ajax("api/admin/permission",
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
  AdminUserAddView = Backbone.View.extend
    template: _.template_braces($("#templ-admin-user-add").html())
    events:
      "click #apply-add" : "apply_add"
    apply_add: ->
      list = $.makeArray(@$el.find("form").map((i,x)->
        obj = $(x).serializeObj()
        if !_.isEmpty(obj.name) and !_.isEmpty(obj.furigana)
          obj
      ))
      $.ajax("api/user/create_users",
        data: JSON.stringify({list:list})
        contentType: "application/json"
        type: "POST").done( -> alert("追加完了"))
    initialize: ->
      @collection = @options.collection
      @render()
    render: ->
      @$el.html(@template(data:_.pick(@collection,"attr_values","key_names","key_values")))
      @$el.appendTo(@options.target)

  init: ->
    collection = new AdminCollection()
    window.admin_view = new AdminView(collection: collection)
    window.admin_edit_view = new AdminEditView(collection: collection)
