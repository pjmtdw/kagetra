import Result from '../components/Result.vue';
import ResultList from '../components/ResultList.vue';
import ResultRecord from '../components/ResultRecord.vue';
import ResultPromotion from '../components/ResultPromotion.vue';
import ResultRanking from '../components/ResultRanking.vue';

export default [
  {
    path: '/list/:year(\\d+)',
    component: ResultList,
    props: true,
  }, {
    path: '/list',
    component: ResultList,
    props: {
      year: (new Date()).getFullYear().toString(),
    },
  }, {
    path: '/record/:name',
    component: ResultRecord,
    props: route => ({
      name: route.params.name,
      page: Number(route.query.page) || 1,
    }),
  }, {
    path: '/record',
    redirect: '/record/myself',
  }, {
    path: '/promotion/ranking',
    component: ResultPromotion,
    props: {
      recent: false,
    },
  }, {
    path: '/promotion',
    component: ResultPromotion,
    props: {
      recent: true,
    },
  }, {
    path: '/ranking',
    component: ResultRanking,
    props: route => _.mapKeys(route.query, (v, k) => `_${k}`),
  }, {
    path: '/:contestId(\\d+)',
    component: Result,
    props: true,
  }, {
    path: '*',
    component: Result,
  },
];
