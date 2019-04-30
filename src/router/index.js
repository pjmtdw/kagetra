import Vue from 'vue';
import VueRouter from 'vue-router';
import store from '../store';
import top from './top';
import bbs from './bbs';
import misc from './misc';

Vue.use(VueRouter);

const router = new VueRouter({
  mode: 'history',
  base: process.env.BASE_URL,
  routes: [
    ...top,
    ...misc,
    ...bbs,
  ],
});

// Authentication check
router.beforeEach((to, from, next) => {
  if (to.meta.public || store.getters['auth/isAuthenticated']) {
    next();
  } else {
    next(`/login?redirect=${to.path}`);
    // Toast.open({
    //   type: 'is-danger',
    //   position: 'is-bottom',
    //   message: 'ログインが必要です',
    // });
  }
});

// Title can be set by both route meta field and component option
router.afterEach((to) => {
  if (to.meta && to.meta.title) {
    document.title = `${to.meta.title}  - 景虎`;
  }
});

Vue.mixin({
  beforeRouteEnter(to, from, next) {
    next((vm) => {
      const { title } = vm.$options;
      if (title) {
        document.title = `${title} · ${document.title}`;
      }
    });
  },
});

export default router;
