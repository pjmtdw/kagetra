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

import NewCommentForm from './components/subcomponents/NewCommentForm.vue';
import CommentList from './components/subcomponents/CommentList.vue';
import PlayerSearch from './components/subcomponents/PlayerSearch.vue';
import ContestDialog from './components/subcomponents/ContestDialog.vue';
import FilePost from './components/subcomponents/FilePost.vue';

Vue.use(VueRouter);

// コンポーネント
Vue.component('new-comment-form', NewCommentForm);
Vue.component('comment-list', CommentList);
Vue.component('player-search', PlayerSearch);
Vue.component('contest-dialog', ContestDialog);
Vue.component('file-post', FilePost);

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
