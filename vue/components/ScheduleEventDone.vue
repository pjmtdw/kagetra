<template>
  <main id="container" class="mx-auto">
    <div class="mt-3">
      <h4 class="text-black-50 border-bottom">過去の行事</h4>
    </div>
    <nav class="mt-3">
      <ul class="pagination justify-content-center">
        <li v-for="p in pages" :key="p" class="page-item" :class="{ active: p == page }">
          <router-link class="page-link" :to="`/ev_done/${p}`">{{ p }}</router-link>
        </li>
      </ul>
    </nav>
    <div class="container">
      <div class="row">
        <div v-for="e in eventList" :key="e.id" class="col-12 col-md-6 py-2">
          <div class="card">
            <h5 class="card-header">
              {{ e.name }}
            </h5>
            <div class="card-body">
              <h6 class="card-subtitle text-muted">
                <span v-if="e.date">{{ e.date }}</span>
                <span v-html="$_timeRange(e.start_at, e.end_at)"/>
                <br>
                <span v-if="e.place">@{{ e.place }}</span>
              </h6>
              <div class="mt-2">
                <button class="btn btn-info" @click="openInfo(e.id)">情報</button>
                <button class="btn btn-info" @click="openComment(e.id)">コメント</button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    <nav class="mt-3">
      <ul class="pagination justify-content-center">
        <li v-for="p in pages" :key="p" class="page-item" :class="{ active: p == page }">
          <router-link class="page-link" :to="`/ev_done/${p}`">{{ p }}</router-link>
        </li>
      </ul>
    </nav>

    <!-- dialog -->
    <EventInfoDialog ref="infoDialog" @openedit="openEdit" @opencomment="openComment"/>
    <EventEditDialog ref="editDialog" @done="fetch"/>
    <EventCommentDialog ref="commentDialog" @openinfo="openInfo"/>
  </main>
</template>
<script>
import DialogMixin from './subcomponents/DialogMixin';

export default {
  mixins: [DialogMixin],
  props: {
    page: {
      type: String,
      required: true,
      validator(v) {
        return !_.isNaN(Number(v));
      },
    },
  },
  data() {
    return {
      pages: null,
      eventList: null,
    };
  },
  watch: {
    page() {
      this.fetch();
    },
  },
  created() {
    this.fetch();
  },
  methods: {
    fetch() {
      const data = this.page === null ? null : { page: this.page };
      axios.get('/schedule/ev_done', { params: data }).then((res) => {
        this.pages = res.data.pages;
        this.eventList = res.data.list;
      }).catch(this.$_makeOnFail('取得に失敗しました'));
    },
  },
};
</script>
<style lang="scss" scoped>
#container {
  width: 100%;
  max-width: 750px;
}
</style>
