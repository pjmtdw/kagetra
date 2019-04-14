import Vue from 'vue';
import Vuex from 'vuex';
import auth from './auth';
import screen from './screen';

Vue.use(Vuex);

export default new Vuex.Store({
  strict: process.env.NODE_ENV !== 'production',
  modules: {
    auth,
    screen,
  },
});
