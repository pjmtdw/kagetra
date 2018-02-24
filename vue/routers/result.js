import result from '../components/result.vue';
import resultList from '../components/result_list.vue';

export default [{
  name: 'list',
  path: '/list/:year',
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
  path: '/:contest_id',
  component: result,
  props: true,
}, {
  path: '*',
  component: result,
  props: {
    contest_id: '-1',
  },
}];
