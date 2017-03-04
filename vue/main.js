import Vue from 'vue';

import addrbook from './components/addrbook.vue'
import album from './components/album.vue'
import bbs from './components/bbs.vue'
import result from './components/result.vue'
import schedule from './components/schedule.vue'
import top from './components/top.vue'
import wiki from './components/wiki.vue'

const routes = {
  addrbook,
  album,
  bbs,
  result,
  schedule,
  top,
  wiki
}

const route = routes[location.pathname.substr(1)]

new Vue({
  el: '#app',
  render: h => h(route)
})
