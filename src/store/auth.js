import axios from 'axios';

export const Status = {
  not_authorized: 0,
  loading: 1,
  shared_ok: 2,
  success: 3,
  error: 4,
};

export default {
  namespaced: true,
  state: {
    status: Status.loading,
    user: null,
    login_uid: null,
    login_uname: null,
  },
  getters: {
    isAuthenticated(state) {
      return state.status === Status.success;
    },
    hasAuthority(state, getters) {
      return (requirement) => {
        if (requirement === 'login') return getters.isAuthenticated;
        if (requirement === 'subadmin') return state.user && state.user.is_subadmin;
        if (requirement === 'admin') return state.user && state.user.is_admin;
        return true;
      };
    },
    hasError(state) {
      return state.status === Status.error;
    },
  },
  mutations: {
    request(state) {
      state.status = Status.loading;
    },
    shared_ok(state, data) {
      state.status = Status.shared_ok;
      if (data) {
        state.login_uid = data.login_uid;
        state.login_uname = data.login_uname;
      }
    },
    success(state, data) {
      state.status = Status.success;
      state.user = data.user;
      state.login_uid = data.login_uid;
      state.login_uname = data.login_uname;
    },
    error(state) {
      state.status = Status.error;
    },
    logout(state) {
      state.status = Status.not_authorized;
      state.user = null;
    },
  },
  actions: {
    init({ commit }) {
      return new Promise((resolve) => {
        commit('request');
        axios.get('/user/auth/init').then((res) => {
          if (res.data.user) commit('success', res.data);
          else if (res.data.shared) commit('shared_ok', res.data);
          else commit('logout');
          resolve(res);
        });
      });
    },
    request_shared({ commit }, password) {
      return new Promise((resolve, reject) => {
        commit('request');
        axios.post('/user/auth/shared', { password }).then((res) => {
          commit('shared_ok');
          resolve(res);
        }).catch((err) => {
          commit('error');
          reject(err);
        });
      });
    },
    request_user({ commit }, data) {
      return new Promise((resolve, reject) => {
        commit('request');
        axios.post('/user/auth/user', data).then((res) => {
          commit('success', res.data);
          resolve(res);
        }).catch((err) => {
          commit('error');
          reject(err);
        });
      });
    },
    logout({ commit }) {
      return new Promise((resolve, reject) => {
        axios.get('/user/logout').then(() => {
          commit('logout');
          resolve();
        }).catch((err) => {
          reject(err);
        });
      });
    },
  },
};
