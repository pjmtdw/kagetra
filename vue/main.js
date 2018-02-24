import Vue from 'vue';
import VueRouter from 'vue-router';

import addrbook from './routers/addrbook';
import album from './routers/album';
import bbs from './routers/bbs';
import result from './routers/result';
import schedule from './routers/schedule';
import top from './routers/top';
import wiki from './routers/wiki';

import misc from './misc';
import playerSearch from './components/player_search.vue';

Vue.use(VueRouter);
Vue.component('player-search', playerSearch);

const routes = {
  addrbook,
  album,
  bbs,
  result,
  schedule,
  top,
  wiki,
};

/* global location */
const routeName = location.pathname.split('/')[1];
const route = routes[routeName];

misc(routeName);

const router = new VueRouter({
  routes: route,
  base: location.pathname,
});

/* eslint-disable no-new */
new Vue({
  router,
}).$mount('#app');
