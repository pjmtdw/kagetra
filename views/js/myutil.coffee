define (require, exports, module) ->
  require("underscore").mixin
    wrap_submit: (f) ->
      ->
        try
          f()
        catch e
          console.log e.message
        return false
