import Album from '../components/Album.vue';
import AlbumGroup from '../components/AlbumGroup.vue';
import AlbumItem from '../components/AlbumItem.vue';
import AlbumStat from '../components/AlbumStat.vue';
import AlbumCommentLog from '../components/AlbumCommentLog.vue';
import AlbumSearch from '../components/AlbumSearch.vue';

export default [
  {
    path: '/:id(\\d+)',
    component: AlbumItem,
    props: route => ({
      id: Number(route.params.id),
    }),
  },
  {
    path: '/group/:id(\\d+)',
    component: AlbumGroup,
    props: route => ({
      id: Number(route.params.id),
    }),
  },
  {
    path: '/stat',
    component: AlbumStat,
  },
  {
    path: '/comment_log',
    component: AlbumCommentLog,
  },
  {
    path: '/search/:q',
    component: AlbumSearch,
    props: true,
  },
  {
    path: '/',
    component: Album,
  },
];
