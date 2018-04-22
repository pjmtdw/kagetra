import result from '../components/Result.vue';
import resultList from '../components/ResultList.vue';

export default [{
  name: 'list',
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
  name: 'result',
  path: '/:contestId(\\d+)',
  component: result,
  props: true,
}, {
  path: '*',
  component: result,
}];
