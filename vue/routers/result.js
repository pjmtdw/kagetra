import result from '../components/Result.vue';
import resultList from '../components/ResultList.vue';
import resultRecord from '../components/ResultRecord.vue';
import resultPromotion from '../components/ResultPromotion.vue';
import resultRanking from '../components/ResultRanking.vue';

export default [
  {
    path: '/list/:year(\\d+)',
    component: resultList,
    props: true,
  }, {
    path: '/list',
    component: resultList,
    props: {
      year: (new Date()).getFullYear().toString(),
    },
  }, {
    path: '/record/:name',
    component: resultRecord,
    props: route => ({
      name: route.params.name,
      page: Number(route.query.page) || 1,
    }),
  }, {
    path: '/record',
    redirect: '/record/myself',
  }, {
    path: '/promotion/ranking',
    component: resultPromotion,
    props: {
      recent: false,
    },
  }, {
    path: '/promotion',
    component: resultPromotion,
    props: {
      recent: true,
    },
  }, {
    path: '/ranking',
    component: resultRanking,
    props: route => _.mapKeys(route.query, (v, k) => `_${k}`),
  }, {
    path: '/:contestId(\\d+)',
    component: result,
    props: true,
  }, {
    path: '*',
    component: result,
  },
];
