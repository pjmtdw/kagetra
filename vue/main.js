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
import misc from './routers/misc';

const routes = _.assign({
  addrbook,
  album,
  bbs,
  result,
  schedule,
  top,
  wiki,
}, misc);

const path = location.pathname.split('/');
const isPublic = path[1] === 'public' || location.pathname === '/';
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

// set baseurl
if (isPublic) axios.defaults.baseURL = '/public/api';
else axios.defaults.baseURL = '/api';

// init
init();

// インスタンスを生成
/* eslint-disable no-new */
$.vm = new Vue({
  router,
  template: '<router-view/>',
}).$mount('#container');
