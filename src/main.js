import Vue from 'vue';
import App from './App.vue';
import router from './router';
import store from './store';
import './init';

store.dispatch('auth/init').then(() => {
  new Vue({
    ...App,
    router,
    store,
  }).$mount('#app');
});
