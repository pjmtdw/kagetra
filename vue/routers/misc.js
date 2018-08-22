import login from '../components/Login.vue';

export default {
  '': [
    {
      path: '',
      component: login,
    },
    {
      path: '*',
      redirect: '/',
    },
  ],
};
