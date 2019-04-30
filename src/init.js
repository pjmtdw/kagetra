import Vue from 'vue';
import BootstrapVue from 'bootstrap-vue';
import axios from 'axios';
import store from './store';
import { initMessages } from './utils';
import { VIcon } from './basics';

Vue.use(BootstrapVue);
Vue.component('VIcon', VIcon);
initMessages();

Vue.prototype.$http = axios;

axios.defaults.baseURL = '/api';
axios.interceptors.response.use(undefined, (err) => {
  const { data } = err.response;
  if (!data || data.error_message) {
    Vue.prototype.$message.error(data.error_message || '通信に失敗しました');
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
