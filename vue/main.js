import Vue from 'vue';

import addrbook from './components/addrbook.vue';
import album from './components/album.vue';
import bbs from './components/bbs.vue';
import result from './components/result.vue';
import schedule from './components/schedule.vue';
import top from './components/top.vue';
import wiki from './components/wiki.vue';

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

axios.interceptors.response.use(null, (error) => {
  // TODO: Eslintに警告されないようなちゃんとしたダイアログにする
  /* global alert */
  /* eslint-disable no-alert */
  alert(`エラー: ${error.response.data.error_message}`);
  return Promise.reject(error);
});

/* eslint-disable no-new */
new Vue({
  el: '#app',
  render: h => h(route),
});
