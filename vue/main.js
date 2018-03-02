import Vue from 'vue';
import VueRouter from 'vue-router';

import addrbook from './routers/addrbook';
import album from './routers/album';
import bbs from './routers/bbs';
import result from './routers/result';
import schedule from './routers/schedule';
import top from './routers/top';
import wiki from './routers/wiki';

import util from './util';
import playerSearch from './components/player_search.vue';
import contestDialog from './components/contest_dialog.vue';
import filePost from './components/file_post.vue';

Vue.use(VueRouter);
Vue.component('player-search', playerSearch);
Vue.component('contest-dialog', contestDialog);
Vue.component('file-post', filePost);

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

util(routeName);

const router = new VueRouter({
  routes: route,
  base: location.pathname,
});

/* eslint-disable no-new */
new Vue({
  router,
}).$mount('#app');
