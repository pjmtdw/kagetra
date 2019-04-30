<template>
  <div v-if="loaded" class="pb-4">
    <b-nav pills class="justify-content-between mt-4">
      <b-nav-item v-if="prev" :to="`/bbs/${prev.id}`" class="pr-1 mw-50">&laquo; {{ prev.title }}</b-nav-item>
      <b-nav-item v-if="next" :to="`/bbs/${next.id}`" class="pl-1 mw-50">{{ next.title }} &raquo;</b-nav-item>
    </b-nav>
    <thread-view v-if="thread" :thread="thread" class="mt-2" @update="fetch"/>
    <b-card v-else border-variant="danger" header="このスレッドは非公開です" header-text-variant="danger" align="center"/>
  </div>
</template>
<script>
import ThreadView from './ThreadView.vue';

export default {
  components: {
    ThreadView,
  },
  props: {
    id: {
      type: Number,
      required: true,
    },
  },
  data() {
    return {
      loaded: false,
      thread: null,
      prev: null,
      next: null,
    };
  },
  watch: {
    id() {
      this.fetch();
    },
  },
  created() {
    this.fetch();
  },
  methods: {
    fetch() {
      this.$http.get(`/bbs/thread/${this.id}`).then((res) => {
        this.thread = res.data.thread;
        this.prev = res.data.prev;
        this.next = res.data.next;
        this.loaded = true;
      });
    },
  },
};
</script>
