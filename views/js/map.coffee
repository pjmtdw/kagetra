define (require,exports,module)->
  $l = require('leaflet')
  $mc = require('map_common')
  mymap = null
  is_edit_mode = false
  map_markers = {}
  marker_current_location = null
  map_bookmark_model = null
  CURRENT_LOCATION_LABEL = "現在地"
  current_location_pending = false
  current_location_retry = 0


  remove_current_location_marker = ->
    if not _.isNull(marker_current_location)
      mymap.removeLayer(marker_current_location)
      marker_current_location = null

  end_edit_buttons = (has_bookmark)->
    is_edit_mode = false
    $("#bookmark-cancel").addClass("hide")
    $("#bookmark-new").removeClass("hide")
    if has_bookmark
      $("#bookmark-edit").removeClass("hide")
    else
      $("#bookmark-edit").addClass("hide")
    $("#bookmark-edit-buttons").addClass("hide")
    $(".marker-delete").addClass("hide")
    $(".marker-edit").addClass("hide")

  start_edit_buttons = ->
    is_edit_mode = true
    $("#bookmark-cancel").removeClass("hide")
    $("#bookmark-new").addClass("hide")
    $("#bookmark-edit").addClass("hide")
    $("#bookmark-edit-buttons").removeClass("hide")
    $(".marker-delete").removeClass("hide")
    $(".marker-edit").removeClass("hide")

  get_geo_links = (lat,lng,popup) ->
    label = encodeURIComponent(popup.title)
    zoom = mymap.getZoom()
    if _.is_ios()
      apple = "maps://maps.apple.com?z=#{zoom}&ll=#{lat},#{lng}&q=#{lat},#{lng}"
      google = "comgooglemaps://?zoom=#{zoom}&center=#{lat},#{lng}&q=#{lat},#{lng}(#{label})"
      "[<a href='#{apple}'>アプリA</a>] [<a href='#{google}'>アプリG</a>]"
    else
      geo = "geo:#{lat},#{lng}?z=#{zoom}&q=#{lat},#{lng}(#{label})"
      "<a href='#{geo}' target='_blank' >アプリで開く</a>"


  show_marker = (add_to_menu,editable,latlng,popup) ->
    marker = new $l.Marker(latlng, draggable:true)
    mymap.addLayer(marker)
    txt = get_geo_links(latlng.lat,latlng.lng,popup)
    if popup.title?
      txt += "<br><strong>"+_.escape(popup.title)+"</strong>"
    if popup.description?
      txt += "<br>"+_.markdown_small(popup.description)
    marker.bindPopup(txt).openPopup()
    if add_to_menu
      map_markers[marker._leaflet_id] = {marker:marker,popup:popup}
      window.map_markers_view.update(marker._leaflet_id,editable)
    marker

  marker_to_json = (obj) ->
    {
      latlng: obj.marker._latlng
      popup: obj.popup
    }
  MapMarkersView = Backbone.View.extend
    template: _.template_braces($("#templ-map-marker-item").html())
    el: "#map-markers"
    events:
      "click .marker-delete" : "marker_delete"
      "click .marker-edit" : "marker_edit"
      "click .marker-title" : "marker_popup"
    render: ->
      remove_current_location_marker()
      $("#map-markers-body").empty()
      $("#map-markers-body").append(
        @template(data:{id:"CURRENT_LOCATION",title:CURRENT_LOCATION_LABEL})
      )
    update: (id,editable)->
      t = map_markers[id].popup.title
      html = @template(data:{id:id,title:t})
      elem = $("#map-markers-body").append(html)
      if editable
        elem.find(".marker-edit").removeClass("hide")
        elem.find(".marker-delete").removeClass("hide")
    switch_current_location_pending_state: (state)->
      current_location_pending = state
      current_location_retry = 0
      elem = $("[data-id='CURRENT_LOCATION']").find(".marker-title")
      if state
        elem.html("取得中..")
      else
        elem.html(CURRENT_LOCATION_LABEL)
        
    marker_popup: (ev)->
      remove_current_location_marker()
      id = $(ev.target).closest("[data-id]").data("id")
      that = this
      if id == "CURRENT_LOCATION"
        return if current_location_pending
        @switch_current_location_pending_state(true)
        if navigator?.geolocation?.getCurrentPosition?
          onsuccess = (position)->
            c = position.coords
            geo = {lat:c.latitude, lng:c.longitude}
            marker_current_location = show_marker(false, false, geo, {title:CURRENT_LOCATION_LABEL,description:""})
            zoom = Math.max(mymap.getZoom(),15)
            mymap.setView(geo, zoom)
            that.switch_current_location_pending_state(false)
          onerror = (err)->
            if err.code == 3 and current_location_retry == 0
              # err.code == 3 は TIMEOUT なので enableHighAccuracy: false で再試行してみる
              current_location_retry = 1
              console.log "hoge"
              navigator.geolocation.getCurrentPosition(onsuccess,onerror,{
                enableHighAccuracy: false
                timeout: 6000
                maximumAge: 0
              })
            else
              _.cb_alert("エラー(#{err.code}): #{err.message}")
              that.switch_current_location_pending_state(false)
          navigator.geolocation.getCurrentPosition(onsuccess,onerror,{
            enableHighAccuracy: true
            timeout: 12000
            maximumAge: 0
          })
        else
          _.cb_alert("お使いのブラウザでは位置情報を取得できません")
          that.switch_current_location_pending_state(false)
      else
        mymap.setView(map_markers[id].marker._latlng)
        map_markers[id].marker.openPopup()
    remove_marker: (target)->
      tgt = $(target).closest("[data-id]")
      id = tgt.data("id")
      if id == "CURRENT_LOCATION"
        return
      mymap.removeLayer(map_markers[id].marker)
      delete map_markers[id]
      tgt.remove()

    marker_delete: (ev)->
      @remove_marker(ev.target)

    marker_edit: (ev)->
      tgt = $(ev.target).closest("[data-id]")
      id = tgt.data("id")
      if id == "CURRENT_LOCATION"
        return
      mm = map_markers[id]
      that = this
      _.cb_template("マーカー編集", ".marker-title", "#templ-map-marker-dialog", mm.popup).done((r)->
        that.remove_marker(ev.target)
        show_marker(true,true,mm.marker._latlng,r)
      )

  MapBookmarksModel = Backbone.Model.extend
    url: "api/map/bookmark/list"

  MapMenuView = Backbone.View.extend
    el:"#bookmark-menu"
    events:
      "change #bookmark-list" : "change_bookmark"
      "click #bookmark-new" : "bookmark_new"
      "click #bookmark-cancel" : "bookmark_cancel"
      "click #bookmark-edit" : "bookmark_edit"
      "click #bookmark-save" : "bookmark_save"
      "click #bookmark-delete" : "bookmark_delete"
      "click #bookmark-change-title" : "bookmark_change_title"
    bookmark_change_title: (ev)->
      _.cb_prompt("ブックマークタイトル",map_bookmark_model.get('title')).done((r)->
        map_bookmark_model.set('title',r)
        $("#bookmark-list").find(":selected").text(r)
      )
    change_bookmark: (ev)->
      bid = $("#bookmark-list").find(":selected").data("bookmark-id")
      if bid == "empty"
        window.map_router.navigate("",{trigger:true})
      else if bid == "search"
        $mc.map_bookmark_search().done((data)->
          window.map_router.navigate("bookmark/#{data.id}",{trigger:true})
        )
      else if bid?
        window.map_router.navigate("bookmark/#{bid}",{trigger:true})

    initialize: ->
      @model = new MapBookmarksModel()
      @listenTo(@model,"sync",@render)
      @init_map_search()
    init_map_search: ->
      obj = $("#map-search")
      obj.select2(
        width: 'resolve'
        placeholder: '検索'
        minimumInputLength: 2
        dropdownCss: {
          width: "20em"
        }
        ajax:
          url: 'api/map/search'
          type: "POST"
          quietMillis: 1000
          data: (term,page)->
            q: term
            lat: mymap.getCenter().lat
            lng: mymap.getCenter().lng
          results: (data,page) -> data
        id: (x)->x.latlng
      )
      obj.on("change",->
        data = obj.select2("data")
        zoom = Math.max(mymap.getZoom(),15)
        mymap.setView(data.latlng, zoom)
        show_marker(true, is_edit_mode, data.latlng, {title:data.text})
        obj.select2('data',{id:null,text:'検索'})
      )

    fetch_and_render: (opts)->
      if opts.no_select
        delete @options['id']
        delete @options['fetch_title']
      else
        @options = _.extend(@options,opts)
      @model.fetch()
    render: ->
      $("#bookmark-list").empty()
      $("#bookmark-list").append($("<option>",text:"-- ブックマーク --").data("bookmark-id","empty"))
      found = false
      for b in @model.get("list")
        e = $("<option>",text:b.title).data("bookmark-id",b.id)
        if String(b.id) == String(@options.id)
          found = true
          e.prop("selected","selected")
        $("#bookmark-list").append(e)
      if (@options.id == "new" or not found) and @options.fetch_title?
        elem = $("<option>",text:@options.fetch_title).prop("selected","selected").data("bookmark-id",@options.id)
        $("#bookmark-list").append(elem)
      $("#bookmark-list").append($("<option>",text:"(検索)").data("bookmark-id","search"))
      if @options.id == "new"
        $("#bookmark-edit").click()
    bookmark_cancel: ->
      Backbone.history.loadUrl()
    bookmark_new: ->
      window.map_router.navigate("bookmark/new",{trigger:true})
    bookmark_edit: (ev)->
      start_edit_buttons()
      mymap.on('click', (ev) ->
        _.cb_template("マーカー編集", ".marker-title", "#templ-map-marker-dialog", {}).done((r)->
          show_marker(true,true,ev.latlng,r)
        )
      )
    bookmark_save: ->
      model = map_bookmark_model
      isNew = model.isNew()
      model.set("zoom",mymap.getZoom())
      model.set(_.pick(mymap.getCenter(),"lat","lng"))
      model.set("markers",_.map(_.values(map_markers),marker_to_json))
      model.save().done((data)->
        if data._error_?
          _.cb_alert(data._error_)
        else
          _.cb_alert("保存しました").always(->
            if isNew
              window.map_router.navigate("bookmark/#{data.id}",{trigger:true,replace:true})
          )
      )
    bookmark_delete: ->
      _.cb_prompt("削除するにはdeleteと入力して下さい").done((r)->
        if r == "delete"
          map_bookmark_model.destroy().done((data)->
            if data._error_?
              _.cb_alert(data._error_)
            else
              _.cb_alert("削除しました")
              window.map_router.navigate("",{trigger:true,replace:true})
          )
      )
    
  MapBookmarkModel = Backbone.Model.extend
    urlRoot: "api/map/bookmark"
  MapRouter = Backbone.Router.extend
    routes:
      "" : "start"
      "bookmark/:id" : "show_bookmark"
    clear: ->
      mymap.off('click')
      for k,v of map_markers
        mymap.removeLayer(v.marker)
      map_markers = {}
      window.map_markers_view.render()
    start: ->
      @clear()
      mymap.setView([35.6825, 139.7521], 5)
      window.map_menu_view.fetch_and_render(no_select:true)
      end_edit_buttons(false)
    show_bookmark: (id) ->
      @clear()
      that = this
      if id == "new"
        _.cb_prompt("ブックマークの名前").done((title)->
          map_bookmark_model = new MapBookmarkModel(title:title)
          start_edit_buttons()
          window.map_menu_view.fetch_and_render(id:"new",fetch_title:title)
        ).fail(->
          window.history.back()
        )
      else
        end_edit_buttons(true)
        map_bookmark_model = new MapBookmarkModel(id:id)
        mdl = map_bookmark_model
        that = this
        mdl.fetch().done( ->
          mymap.setView(mdl.pick('lat','lng'), mdl.get('zoom'))
          for m in mdl.get('markers')
            show_marker(true,false,m.latlng,m.popup)
          window.map_menu_view.fetch_and_render(id:id,fetch_title:mdl.get('title'))
        )
  init: ->
    $l.Icon.Default.imagePath = _.initial($("[href$='/leaflet.css']").attr("href").split("/")).join("/") + "/images"
    mymap = $l.map('map')
    $l.tileLayer(g_map_tile_url + '/{z}/{x}/{y}.png', {}).addTo(mymap)
    window.map_router = new MapRouter()
    window.map_markers_view = new MapMarkersView()
    window.map_menu_view = new MapMenuView()
    mymap.attributionControl.setPrefix('') # デフォルトでは右下に出る leaflet のロゴマークが「一番上へ」と被るので消去
    # show scale bar
    $l.control.scale(
      imperial: false
      maxWidth: 120
    ).addTo(mymap)
    Backbone.history.start()
