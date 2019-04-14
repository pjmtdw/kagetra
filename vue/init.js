import Vue from 'vue';
import Buefy from 'buefy';
import { Toast } from 'buefy/dist/components/toast';
import axios from 'axios';
import store from './store';

Vue.use(Buefy, {
  defaultIconPack: 'fa',
});

axios.defaults.baseURL = '/api';
axios.interceptors.response.use(undefined, (err) => {
  if (err.response.data.error_message) {
    Toast.open({
      type: 'is-danger',
      position: 'is-bottom',
      message: err.response.data.error_message,
    });
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

store.dispatch('auth/init');
window.onresize = () => store.commit('screen/resize');
