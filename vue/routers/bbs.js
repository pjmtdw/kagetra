import Bbs from '../components/Bbs.vue';

export default [
  {
    path: '/:page(\\d+)',
    component: Bbs,
    props: true,
  }, {
    path: '*',
    component: Bbs,
    props: { page: '1' },
  },
];
