import Vue from 'vue';
import VueRouter from 'vue-router';

import addrbook from './routers/addrbook';
import album from './routers/album';
import bbs from './routers/bbs';
import result from './routers/result';
import schedule from './routers/schedule';
import top from './routers/top';
import wiki from './routers/wiki';

Vue.use(VueRouter);

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
const route = routes[location.pathname.substr(1)];

const router = new VueRouter({
  routes: route,
  base: location.pathname,
});


axios.interceptors.response.use(null, (error) => {
  // TODO: Eslintに警告されないようなちゃんとしたダイアログにする
  /* global alert */
  /* eslint-disable no-alert */
  alert(`エラー: ${error.response.data.error_message}`);
  return Promise.reject(error);
});

/* eslint-disable no-new */
new Vue({
  router,
}).$mount('#app');
