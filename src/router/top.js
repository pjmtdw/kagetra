export default [
  { path: '/', redirect: '/top' },
  {
    path: '/top',
    name: 'Top',
    component: () => import(/* webpackChunkName: "top" */ '@/pages/Top.vue'),
    meta: {
      title: 'Top',
      public: true,
    },
  },
];
