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

// for navbar
$(`nav #${location.pathname.substr(1)}`).addClass('active');

// 通知機能追加
// @param type 通知のスタイル(bootstrapのalert準拠. primaryなど)
// @param message 通知の内容
$.notify = (type, message) => {
  // クリア
  if (type === 'clear') {
    $('.notify').remove();
    return;
  }
  // 重ならないようにずらす関数
  const alignNotify = () => {
    $('.notify').css('top', (i) => {
      let height = 0;
      $(`.notify:lt(${i})`).each((j, e) => {
        height += $(e).outerHeight(true);
      });
      return height;
    });
  };

  const $notify = $('<div role="alert"></div>').addClass(`notify alert alert-${type} alert-dismissible fade show w-25 m-1`)
    .css({
      position: 'absolute',
      'z-index': 200,
      right: '10px',
      'box-shadow': '5px 5px 10px 0 rgba(0, 0, 0, 0.2)',
      'min-width': '150px',
    })
    .html(message)
    .append($('<button class="close p-0 type="button" data-dismiss="alert" aria-label="Close"></button>')
      .css({ top: 0, right: 0 })
      .html('<span aria-hidden="true">&times;</span>'),
    )
    .prependTo('#app');

  alignNotify();
  $notify.on('closed.bs.alert', alignNotify);

  // 30秒後に消える
  setTimeout(() => { $notify.remove(); }, 30 * 1000);
};

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

