<template>
  <div v-if="loaded">
    <bbs-pagination class="mt-4 mb-2" :pages="pages" :page="page"/>
    <thread-view v-for="thread in threads" :key="thread.id" :thread="thread" class="mb-4" @update="fetch"/>
    <bbs-pagination class="pb-4 mb-0" :pages="pages" :page="page"/>
  </div>
</template>
<script>
import { range } from 'lodash';
import BbsPagination from './BbsPagination.vue';
import ThreadView from './ThreadView.vue';

export default {
  components: {
    BbsPagination,
    ThreadView,
  },
  props: {
    page: {
      type: Number,
      required: true,
    },
    query: {
      type: String,
      default: null,
    },
  },
  data() {
    return {
      loaded: false,
      totalCount: 0,
      perPage: 5,
      threads: [],
    };
  },
  computed: {
    limit() {
      if (this.screenFrom('sm')) return 5;
      if (this.screenWidth >= 425) return this.page < 97 ? 4 : 3;
      return this.page < 97 ? 3 : 2;
    },
    pages() {
      const max = Math.floor((this.totalCount - 1) / this.perPage) + 1;
      let pages;
      if (this.page <= this.limit) {
        pages = range(1, Math.min(max, this.limit * 2) + 1);
      } else if (this.page > max - this.limit) {
        pages = range(this.page - this.limit, max + 1);
      } else {
        pages = range(this.page - this.limit, this.page + this.limit + 1);
      }
      return pages.map(page => ({ link: { query: { page } }, text: page }));
    },
  },
  watch: {
    page() {
      this.fetch();
    },
    query() {
      this.fetch();
    },
  },
  created() {
    this.fetch();
  },
  methods: {
    fetch() {
      let queryUrl = `?page=${this.page}`;
      if (this.query) queryUrl += `&qs=${encodeURIComponent(this.query)}`;
      this.$http.get(`/bbs/threads${queryUrl}`).then((res) => {
        this.totalCount = res.data.count;
        this.perPage = res.data.threads_per_page;
        this.threads = res.data.threads;
        this.loaded = true;
      });
    },
  },
};
</script>
