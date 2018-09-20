import bbs from '../components/Bbs.vue';

export default [{
  path: '/:page(\\d+)',
  component: bbs,
  props: true,
}, {
  path: '*',
  component: bbs,
  props: { page: '1' },
}];
