import Vue from 'vue';
import BootstrapVue from 'bootstrap-vue';
import axios from 'axios';
import { mapGetters, mapState } from 'vuex';
import store from './store';
import { initMessages } from './utils';
import { VIcon, VField, VInput, VTextarea } from './basics';

Vue.use(BootstrapVue);
Vue.component('VIcon', VIcon);
Vue.component('VField', VField);
Vue.component('VInput', VInput);
Vue.component('VTextarea', VTextarea);
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
    computed: {
      ...mapState('screen', {
        screenWidth: 'width',
      }),
      ...mapGetters('screen', {
        screenUntil: 'until',
        screenFrom: 'from',
      }),
    },
  });
}

window.onresize = () => store.commit('screen/resize');
