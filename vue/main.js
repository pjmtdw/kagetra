import Vue from 'vue';
import VueRouter from 'vue-router';

import init from './init';

import addrbook from './routers/addrbook';
import album from './routers/album';
import bbs from './routers/bbs';
import result from './routers/result';
import schedule from './routers/schedule';
import top from './routers/top';
import wiki from './routers/wiki';

/* global location */
const routes = {
  addrbook,
  album,
  bbs,
  result,
  schedule,
  top,
  wiki,
};

const path = location.pathname.split('/');
const isPublic = path[1] === 'public';
const routeName = isPublic ? path[2] : path[1];
const route = routes[routeName];

const router = new VueRouter({
  routes: route,
  base: location.pathname,
});

// Plugin
Vue.use(VueRouter);

// Mixin
Vue.mixin({
  data: () => ({ routeName, isPublic }),
});

// init
init();

// インスタンスを生成
/* eslint-disable no-new */
$.vm = new Vue({
  router,
  template: '<router-view/>',
}).$mount('#container');
