import bbs from '../components/bbs.vue';

export default [{
  name: 'bbs',
  path: '/:page(\\d+)',
  component: bbs,
  props: true,
}, {
  path: '*',
  redirect: '/1',
}];
