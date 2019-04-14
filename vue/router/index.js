import Vue from 'vue';
import VueRouter from 'vue-router';
// import { Toast } from 'buefy/dist/components/toast';
import store from '../store';
import { Home, Login, Top } from '../pages';

Vue.use(VueRouter);

const router = new VueRouter({
  mode: 'history',
  base: process.env.BASE_URL,
  routes: [
    {
      path: '/',
      name: 'Home',
      component: Home,
      meta: {
        public: true,
      },
    },
    {
      path: '/login',
      name: 'Login',
      component: Login,
      meta: {
        public: true,
      },
    },
    {
      path: '/top',
      name: 'Top',
      component: Top,
      meta: {
        public: true,
      },
    },
  ],
});

// Authentication check
router.beforeEach((to, from, next) => {
  if (to.meta.public || store.getters.isAuthenticated) {
    next();
  } else {
    // next('/login?redirect=' + to.path);
    // Toast.open({
    //   type: 'is-danger',
    //   position: 'is-bottom',
    //   message: 'Sign in required',
    // });
    next(false);
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
