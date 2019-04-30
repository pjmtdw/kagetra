import Vue from 'vue';
import BootstrapVue from 'bootstrap-vue';
import axios from 'axios';
import store from './store';
// import { initNotifications } from './utils';
import { VIcon } from './basics';

Vue.use(BootstrapVue);
Vue.component('VIcon', VIcon);
// initNotifications();

Vue.prototype.$http = axios;

axios.defaults.baseURL = '/api';
axios.interceptors.response.use(undefined, (err) => {
  if (!err.response.data || err.response.data.error_message) {
    Vue.prototype.$notify.error(err.response.data.error_message || '通信に失敗しました');
  }
  throw err;
});

if (process.env.NODE_ENV !== 'production') {
  Vue.mixin({
    methods: {
      $_log: console.log,
    },
  });
}

window.onresize = () => store.commit('screen/resize');
