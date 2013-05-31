define (require, exports, module) ->
  _ = require("underscore")
  $ = require("zep_or_jq")
  _.mixin
    wrap_submit: (f) ->
      ->
        try
          _.bind(f,this)()
        catch e
          console.log e
        return false

  $.fn.serializeObj = ->
    o = {}
    a = this.serializeArray()
    $.each a, ->
      if o[this.name]?
        if !o[this.name].push
          o[this.name] = [o[this.name]]
        o[this.name].push(this.value || '')
      else
        o[this.name] = this.value || ''
    o
