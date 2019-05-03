const Schedule = () => import(/* webpackChunkName: "schedule" */ '@/pages/Schedule/Schedule.vue');
const ScheduleMain = () => import(/* webpackChunkName: "schedule" */ '@/pages/Schedule/ScheduleMain.vue');

export default [
  {
    path: '/schedule',
    component: Schedule,
    meta: {
      title: '予定表',
      public: true,
    },
    children: [
      {
        path: '',
        component: ScheduleMain,
        meta: {
          page: 'main',
        },
      },
      {
        path: '/:year(\\d+)-:month(\\d+)',
        component: ScheduleMain,
        props: true,
        meta: {
          page: 'main',
        },
      },
      // {
      //   path: ':threadId(\\d+)',
      //   component: BbsThread,
      //   props: route => ({ id: Number(route.params.threadId) }),
      // },
    ],
  },
];
