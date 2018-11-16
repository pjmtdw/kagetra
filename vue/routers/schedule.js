import Schedule from '../components/Schedule.vue';
import ScheduleEventDone from '../components/ScheduleEventDone.vue';

export default [
  {
    path: '/ev_done/:page(\\d+)',
    component: ScheduleEventDone,
    props: true,
  }, {
    path: '/ev_done',
    component: ScheduleEventDone,
    props: {
      page: '1',
    },
  }, {
    path: '/:year(\\d+)-:month(\\d+)',
    component: Schedule,
    props: true,
  }, {
    path: '/',
    component: Schedule,
  },
];
