define (require,exports,module)->
  $l = require('leaflet')
  mymap = null
  map_markers = {}
  map_bookmark_model = null
  show_marker = (latlng,popup) ->
    marker = new $l.Marker(latlng, draggable:true)
    mymap.addLayer(marker)
    marker.bindPopup(popup).openPopup()
    map_markers[marker._leaflet_id] = marker
    window.map_markers_view.update(marker._leaflet_id)

  marker_to_json = (marker) ->
    {
      latlng: marker._latlng
      popup: marker._popup._content
    }
  MapBookmarksModel = Backbone.Model.extend
    url: "api/map/bookmark/list"
  MapBookmarksView = Backbone.View.extend
    el: "#map-bookmarks"
    events:
      "click #bookmark-new" : "bookmark_new"
    initialize: ->
      @model = new MapBookmarksModel()
      @listenTo(@model,"sync",@render)
      @model.fetch()
    bookmark_new: ->
      window.map_router.navigate("bookmark/new",{trigger:true, replace:true})
    render: ->
      $("#map-bookmarks-body").empty()
      for b in @model.get("list")
        $("#map-bookmarks-body").append(
          $("<a>",{class:"map-bookmark-item",href:"map#bookmark/#{b.id}",text:"#{b.title}"})
        )
  MapMarkersView = Backbone.View.extend
    template: _.template_braces($("#templ-map-marker-item").html())
    el: "#map-markers"
    events:
      "click .marker-delete" : "marker_delete"
      "click .marker-title" : "marker_popup"
    update: (id)->
      t = map_markers[id]._popup._content.split("<br>")[0]
      $("#map-markers-body").append(
        @template(data:{id:id,title:t})
      )
    marker_popup: (ev)->
      id = $(ev.target).closest("[data-id]").data("id")
      mymap.setView(map_markers[id]._latlng)
      map_markers[id].openPopup()

    marker_delete: (ev)->
      tgt = $(ev.target).closest("[data-id]")
      id = tgt.data("id")
      mymap.removeLayer(map_markers[id])
      delete map_markers[id]
      tgt.remove()

  MapMenuView = Backbone.View.extend
    el: "#map-menu"
    events:
      "click #bookmark-save" : "bookmark_save"
      "click .choice" : "switch_mode"
    switch_mode: (ev)->
      @$el.find(".choice").removeClass("active")
      tgt = $(ev.target).closest(".choice")
      tgt.addClass("active")
      if tgt.attr("id") == "mode-marker" 
        mymap.on('click', (ev) ->
          _.cb_prompt("マーカーの説明(&lt;br&gt;で改行)").done((r)->
            show_marker(ev.latlng,r)
          )
        )
      else
        mymap.off('click')
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
              window.map_bookmarks_view.model.fetch()
          )
      )
    
  MapBookmarkModel = Backbone.Model.extend
    urlRoot: "api/map/bookmark"
  MapRouter = Backbone.Router.extend
    routes:
      "" : "start"
      "bookmark/:id" : "show_bookmark"
    start: ->
      mymap.setView([35.6825, 139.7521], 5)
    update_title: ->
      $("#map-menu").removeClass("hide")
      $(".bookmark-title").html(map_bookmark_model.get('title'))
    show_bookmark: (id) ->
      for k,v of map_markers
        mymap.removeLayer(v)
      map_markers = {}
      $("#map-markers-body").empty()
      if id == "new"
        _.cb_prompt("ブックマークの名前").done((title)->
          map_bookmark_model = new MapBookmarkModel(title:title)
        ).fail(->
          map_bookmark_model = new MapBookmarkModel(title:"新規")
        ).always(@update_title)
      else
        map_bookmark_model = new MapBookmarkModel(id:id)
        mdl = map_bookmark_model
        that = this
        mdl.fetch().done( ->
          mymap.setView(mdl.pick('lat','lng'), mdl.get('zoom'))
          for m in mdl.get('markers')
            show_marker(m.latlng,m.popup)
          that.update_title()
        )
  init: ->
    mymap = $l.map('map')
    $l.tileLayer(g_map_tile_url + '/{z}/{x}/{y}.png', {}).addTo(mymap)
    window.map_router = new MapRouter()
    window.map_menu_view = new MapMenuView()
    window.map_bookmarks_view = new MapBookmarksView()
    window.map_markers_view = new MapMarkersView()
    Backbone.history.start()
