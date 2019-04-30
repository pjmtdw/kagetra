const Bbs = () => import(/* webpackChunkName: "bbs" */ '@/pages/Bbs/Bbs.vue');
const BbsThreads = () => import(/* webpackChunkName: "bbs" */ '@/pages/Bbs/BbsThreads.vue');

export default [
  {
    path: '/bbs',
    component: Bbs,
    meta: {
      title: '掲示板',
      public: true,
    },
    children: [
      {
        path: '',
        component: BbsThreads,
        props: route => ({ page: 1, query: route.query.q }),
      },
      {
        path: '/:page(\\d+)',
        component: BbsThreads,
        props: route => ({ page: Number(route.params.page), query: route.query.q }),
      },
    ],
  },
];
