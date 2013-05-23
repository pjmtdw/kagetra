var isZeptoSupported = function(){
  //return '__proto__' in {}
  // currently we cannot use simply-deferred so we use jQuery
  return false
}

define([ isZeptoSupported() ? "zepto" : "jquery"], function(){
  return $
})
