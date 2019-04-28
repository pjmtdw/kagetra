export default [
  {
    path: '/bbs',
    name: 'Bbs',
    component: () => import(/* webpackChunkName: "bbs" */ '@/pages/Bbs.vue'),
    meta: {
      title: '掲示板',
      public: true,
    },
    // children: [
    //   {
    //     path: '',
    //     component: BbsContent,
    //     props: { page: '1' },
    //   },
    //   {
    //     path: '/:page(\\d+)',
    //     component: BbsContent,
    //     props: true,
    //   },
    // ],
  },
];
