define (require,exports,module) ->
  WikiItemView = Backbone.View.extend {}
  WikiPanelView = Backbone.View.extend {}
  init: ->
    window.wiki_item_view = new WikiItemView()
    window.wiki_panel_view = new WikiPanelView()
