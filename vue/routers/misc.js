import Login from '../components/Login.vue';

export default {
  '': [
    {
      path: '',
      component: Login,
    },
    {
      path: '*',
      redirect: '/',
    },
  ],
};
