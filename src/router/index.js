import Vue from 'vue';
import VueRouter from 'vue-router';
import store from '@/store';
import top from './top';
import bbs from './bbs';
import schedule from './schedule';
import misc from './misc';

Vue.use(VueRouter);

const inheritMeta = (route) => {
  if (route.meta && route.children) {
    route.children.forEach((r) => {
      if (!r.meta) r.meta = route.meta;
      else r.meta = { ...route.meta, ...r.meta };
      inheritMeta(r);
    });
  }
};
const routes = [
  ...top,
  ...bbs,
  ...schedule,
  ...misc,
];
routes.forEach(inheritMeta);
const router = new VueRouter({
  mode: 'history',
  base: process.env.BASE_URL,
  routes,
});

// Authentication check
router.beforeEach((to, from, next) => {
  if (to.meta.public || store.getters['auth/isAuthenticated']) {
    next();
  } else {
    next(`/login?redirect=${to.path}`);
    Vue.prototype.$message.error('ログインが必要です');
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
