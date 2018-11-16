import Wiki from '../components/Wiki.vue';
import WikiNewPage from '../components/WikiNewPage.vue';

export default [
  {
    path: '/new',
    component: WikiNewPage,
  },
  {
    path: '/all',
    component: Wiki,
    props: route => ({
      pageId: -Number(route.query.page || 1),
    }),
  },
  {
    path: '/:pageId(\\d+)/:tab',
    component: Wiki,
    props: route => ({
      pageId: Number(route.params.pageId),
      tab: route.params.tab,
    }),
  },
  {
    path: '/:pageId(\\d+)',
    component: Wiki,
    props: route => ({
      pageId: Number(route.params.pageId),
    }),
  },
  {
    path: '/',
    component: Wiki,
    props: {
      pageId: 1,
    },
  },
];
