define (require,exports,module)->
  $l = require('leaflet')
  init: ->
    map = $l.map('map').setView([35.6825, 139.7521], 5)
    $l.tileLayer(g_map_tile_url + '/{z}/{x}/{y}.png', {}).addTo(map)
