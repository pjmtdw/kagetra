const Bbs = () => import(/* webpackChunkName: "bbs" */ '@/pages/Bbs/Bbs.vue');
const BbsThreads = () => import(/* webpackChunkName: "bbs" */ '@/pages/Bbs/BbsThreads.vue');
const BbsThread = () => import(/* webpackChunkName: "bbs" */ '@/pages/Bbs/BbsThread.vue');

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
        props: route => ({ page: Number(route.query.page) || 1, query: route.query.q }),
      },
      {
        path: ':threadId(\\d+)',
        component: BbsThread,
        props: route => ({ id: Number(route.params.threadId) }),
      },
    ],
  },
];
