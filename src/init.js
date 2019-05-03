import Vue from 'vue';
import { mapGetters, mapState } from 'vuex';
import BootstrapVue from 'bootstrap-vue';
import Vue2TouchEvents from 'vue2-touch-events';
import axios from 'axios';
import store from './store';
import { initDialogs } from './utils';
import { VField, VHelp, VIcon, VInput, VTextarea } from './basics';

Vue.use(BootstrapVue);
Vue.use(Vue2TouchEvents);
Vue.component('VField', VField);
Vue.component('VHelp', VHelp);
Vue.component('VIcon', VIcon);
Vue.component('VInput', VInput);
Vue.component('VTextarea', VTextarea);
initDialogs();

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
    computed: {
      ...mapState('screen', {
        screenWidth: 'width',
      }),
      ...mapGetters('auth', ['isAuthenticated']),
      ...mapGetters('screen', {
        screenUntil: 'until',
        screenFrom: 'from',
      }),
    },
  });
}

window.onresize = () => store.commit('screen/resize');
