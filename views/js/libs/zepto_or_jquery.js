var isZeptoSupported = function(){
  return false
  // return '__proto__' in {}
}

define([ isZeptoSupported() ? "zepto" : "jquery"], function(){
  return $
})
