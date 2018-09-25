import schedule from '../components/Schedule.vue';

export default [
  {
    path: '/:year(\\d+)-:month(\\d+)',
    component: schedule,
    props: true,
  }, {
    path: '/',
    component: schedule,
  },
];
