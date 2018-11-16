import Login from '../components/Login.vue';
import Admin from '../components/Admin.vue';
import UTForm from '../components/UTForm.vue';
import Conf from '../components/Conf.vue';
import LoginLog from '../components/LoginLog.vue';

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
  admin: [
    {
      path: '/',
      component: Admin,
    },
  ],
  ut_karuta_list_form: [
    {
      path: '/',
      component: UTForm,
    },
    {
      path: '/:page',
      component: UTForm,
      props: true,
    },
  ],
  user_conf: [
    {
      path: '/',
      component: Conf,
    },
  ],
  login_log: [
    {
      path: '/',
      redirect: '/ranking',
    },
    {
      path: '/ranking',
      component: LoginLog,
      props: {
        page: 'ranking',
      },
    },
    {
      path: '/weekly',
      component: LoginLog,
      props: {
        page: 'weekly',
      },
    },
    {
      path: '/history',
      component: LoginLog,
      props: {
        page: 'history',
      },
    },
  ],
};
