define (require, exports, module) ->
  _ = require("underscore")
  _.mixin
    wrap_submit: (f) ->
      ->
        try
          _.bind(f,this)()
        catch e
          console.log e
        return false
