<template>
  <main id="container" class="mx-auto">
    <!-- スレッド作成, 検索 -->
    <div class="d-flex flex-row">
      <button v-show="!editing" class="btn btn-success m-2" data-toggle="collapse" href="#new-thread-form"
              aria-expanded="false" aria-controls="new-thread-form" @click="showNewThread">
        スレッド作成
      </button>
      <button v-show="editing" id="new-thread-toggle" class="btn btn-outline-success m-2" data-toggle="collapse" href="#new-thread-form"
              aria-expanded="false" aria-controls="new-thread-form" @click="editing = false">
        キャンセル
      </button>
      <form id="search-form" class="ml-auto" @submit.prevent="search">
        <div class="form-group input-group my-2">
          <input v-model="query" class="form-control" name="query" type="search" placeholder="検索文字列">
          <div class="input-group-append">
            <button class="btn btn-secondary" type="button" @click="search">検索</button>
          </div>
        </div>
      </form>
    </div>
    <form id="new-thread-form" class="collapse my-1" @submit.prevent @keydown.shift.enter="postThread">
      <div class="card">
        <div class="form-group m-2">
          <button class="btn btn-success" type="button" @click="postThread">投稿</button>
        </div>
        <div class="form-group form-inline mx-3">
          <label>
            名前
            <input v-model="name" class="form-control ml-md-2" type="text" name="user_name" placeholder="名前" required>
            <div class="invalid-feedback">名前を入力してください</div>
          </label>
          <div class="form-check w-auto ml-5">
            <label class="form-check-label">
              <input v-model="publicThread" class="form-check-input" type="checkbox" name="public">
              外部公開
            </label>
          </div>
        </div>
        <div class="form-group mx-3">
          <label class="w-100">
            タイトル
            <input v-model="title" class="form-control" type="text" name="title" placeholder="タイトル" required>
            <div class="invalid-feedback">タイトルを入力してください</div>
          </label>
        </div>
        <div class="form-group mx-3">
          <label class="w-100">
            内容
            <textarea v-model="body" class="form-control" name="body" :rows="rows" placeholder="内容" required/>
            <div class="invalid-feedback">内容を入力してください</div>
          </label>
        </div>
      </div>
    </form>
    <!-- pagination -->
    <ul class="pagination my-2 justify-content-center">
      <li v-for="i in pages" class="page-item" :class="{ active: page == i }" :key="i">
        <router-link class="page-link" :to="i.toString()">{{ i }}</router-link>
      </li>
    </ul>
    <!-- スレッド -->
    <div v-for="thread in threads" :key="thread.id" class="card mb-4" :class="{'border-primary': thread.public, 'private': !thread.public}">
      <div class="card-header h5">
        <span class="h6">{{ thread.title }}</span>
        <span v-if="thread.public" class="float-right badge badge-primary mx-1">外部公開</span>
        <span v-if="thread.has_new_comment" class="float-right badge badge-info mx-1">新着あり</span>
      </div>
      <CommentList :comments="thread.items" url="/api/bbs/item" item-class="px-3" @done="fetch(page)"/>
      <div>
        <button class="new-item-toggle btn btn-success my-2 ml-3" data-toggle="collapse" :href="`#new-item-form${thread.id}`"
                aria-expanded="false" :aria-controls="`new-item-form${thread.id}`" @click="toggleNewItem">
          書き込む
        </button>
        <NewCommentForm :id="`new-item-form${thread.id}`" class="mx-3 mb-3 mt-2" url="/api/bbs/item" :thread-id="thread.id" @done="postDone"/>
      </div>
    </div>
    <!-- pagination -->
    <ul class="pagination my-2 justify-content-center">
      <li v-for="i in pages" class="page-item" :class="{ active: page == i }" :key="i">
        <router-link class="page-link" :to="i.toString()">{{ i }}</router-link>
      </li>
    </ul>
  </main>
</template>
<script>
/* global g_user_name */
export default {
  props: {
    page: {
      type: String,
      default: '1',
    },
  },
  data() {
    return {
      threads: [],
      pages: [],
      query: '',
      // new thread
      name: g_user_name,
      title: '',
      publicThread: '', // public is reserved
      body: '',
      editing: false,
    };
  },
  computed: {
    rows() {
      return _.max([this.body.split('\n').length, 4]);
    },
  },
  watch: {
    page(val) {
      this.fetch(val);
    },
  },
  created() {
    this.fetch(this.page);
  },
  methods: {
    fetch(page) {
      const baseUrl = '/api/bbs/threads';
      let queryUrl = `?page=${page}`;
      if (this.query) queryUrl += `&qs=${encodeURIComponent(this.query)}`;
      axios.get(`${baseUrl}${queryUrl}`).then((res) => {
        const COUNT = res.data.count;
        const THREADS_PER_PAGE = res.data.threads_per_page;
        const PAGINATE_LIMIT = 5;
        this.threads = res.data.threads;

        const max = Math.floor((COUNT - 1) / THREADS_PER_PAGE) + 1;
        const p = Number(page);

        if (p <= PAGINATE_LIMIT) {
          this.pages = _.range(1, _.min([max, PAGINATE_LIMIT * 2]) + 1);
        } else if (p > max - PAGINATE_LIMIT) {
          this.pages = _.range(p - PAGINATE_LIMIT, max + 1);
        } else {
          this.pages = _.range(p - PAGINATE_LIMIT, p + PAGINATE_LIMIT + 1);
        }
      }).catch(() => {
        this.$_notify('danger', '投稿の取得に失敗しました');
      });
    },
    showNewThread() {
      this.editing = true;
      this.$nextTick(() => $('#new-thread-form input[name="title"]').focus());
    },
    postThread() {
      const $form = $('#new-thread-form');
      if (!$form.check()) return;
      const data = $form.serializeObject();
      axios.post('/api/bbs/thread', data).then(() => {
        /* eslint-disable camelcase */
        this.name = g_user_name;
        this.publicThread = false;
        this.title = '';
        this.body = '';
        $('#new-thread-toggle').click();
        this.$_notify('投稿しました');
        this.fetch(this.page);
      }).catch(() => {
        this.$_notify('danger', '投稿に失敗しました');
      });
    },
    search() {
      this.fetch(this.page);
    },
    toggleNewItem(e) {
      const $toggle = $(e.target);
      $toggle.toggleBtnText('書き込む', 'キャンセル');
      $toggle.toggleClass('btn-success');
      $toggle.toggleClass('btn-outline-success');
    },
    postDone(id) {
      $(`button[href="#new-item-form${id}"]`).click();
      this.fetch(this.page);
    },
  },
};
</script>
<style lang="scss" scoped>
@import '../sass/common.scss';
#container {
  width: 100%;
  max-width: 750px;
}

.card.private {
  border: 1px solid green;
  background-color: #FFD;
}
</style>
