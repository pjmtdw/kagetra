<template>
  <div id="container" class='mx-auto'>
    <div class="d-flex flex-row">
      <button id="new-thread-toggle" class="btn btn-primary m-2" data-toggle="collapse" href="#new-thread-form" aria-expanded="false" aria-controls="new-thread-form">
        スレッド作成
      </button>
      <form id="search-form" class="ml-auto">
        <div class="form-group input-group my-2">
          <input class="form-control" name="query" type="text" placeholder="検索文字列">
          <span class="input-group-btn">
            <button class="btn btn-secondary" type="button" v-on:click="search">検索</button>
          </span>
        </div>
      </form>
    </div>
    <form id="new-thread-form" class="collapse my-1">
      <div class="card card-block">
        <div class="form-group m-2">
          <input class="btn btn-primary" type="button" value="送信" v-on:click="create_new_thread">
        </div>
        <div class="form-group form-inline mx-2">
          <label>名前<input class="form-control mx-2" name="user_name" type="text" v-bind:value="name"></label>
          <div class="form-check ml-5">
            <label class="form-check-label">
              <input class="form-check-input" name="public" type="checkbox">
              外部公開
            </label>
          </div>
        </div>
        <div class="form-group mx-3">
          <label style="width:100%;">タイトル<input class="form-control" type="text" name="title"></label>
        </div>
        <div class="form-group mx-3">
          <label style="width:100%;">内容<textarea class="form-control" name="body" rows="30"></textarea></label>
        </div>
      </div>
    </form>
    <ul class='pagination my-2'>
      <li v-for='i in pages' class='page-item' v-bind:class="{ active: page === String(i) }">
        <router-link class='page-link' :to='i.toString()'>{{i}}</router-link>
      </li>
    </ul>
    <div class='card thread' v-for='thread in threads'>
      <div class='card-header'>
        <span>{{thread.title}}</span>
        <span v-if="thread.public" class="float-right mx-1 is-public">外部公開</span>
        <span v-if="thread.has_new_comment" class="float-right mx-1 is-new">新着あり</span>
      </div>
      <ul class="list-group list-group-flush">
        <li class='list-group-item' v-for='item in thread.items'>
          <div class="thread-info">
            <span class='name'>{{item.user_name}}</span>＠<span class='date'>{{item.date}}</span>
          </div>
          <div>
            {{item.body}}
          </div>
        </li>
      </ul>
    </div>
  </div>
</template>
<script>
/* global g_user_name */
export default {
  props: ['page'],
  created() {
    this.fetch(this.page);
  },
  mounted() {
    const $toggle = $('#new-thread-toggle');
    $toggle.click(
      () => {
        if ($toggle.attr('aria-expanded') === 'true') {
          $toggle.html('スレッド作成');
        } else {
          $toggle.html('キャンセル');
        }
      },
    );

    $('input[name="user_name"]').val(this.name);
    // Enterでsubmitされるかわりに検索を実行
    $('input[name="query"]').on('keypress', (e) => {
      if (e.keyCode === 13) {
        this.search();
        e.preventDefault();
      }
    });
  },
  data() {
    return {
      threads: [],
      pages: [],
      name: g_user_name,
      query: '',
    };
  },
  methods: {
    fetch(page) {
      let url = `/api/bbs/threads?page=${page}`;
      if (this.query) url += `&qs=${encodeURIComponent(this.query)}`;

      axios.get(url).then((res) => {
        const PAGINATE_LIMIT = 5;
        const THREADS_PER_PAGE = res.data.pop().threads_per_page;
        const COUNT = res.data.pop().count;
        this.threads = _.filter(res.data, (v, key) => _.isInteger(key));

        const max = Math.floor((COUNT - 1) / THREADS_PER_PAGE) + 1;
        const p = Number(page);

        if (p <= PAGINATE_LIMIT) {
          this.pages = _.range(1, _.min([max, PAGINATE_LIMIT * 2]) + 1);
        } else if (p > max - PAGINATE_LIMIT) {
          this.pages = _.range(p - PAGINATE_LIMIT, max + 1);
        } else {
          this.pages = _.range(p - PAGINATE_LIMIT, p + PAGINATE_LIMIT + 1);
        }
      });
    },
    create_new_thread() {
      if ($('input[name="title"]').val() === '') {
        $.notify('warning', 'タイトルを入力してください');
        return;
      }
      if ($('textarea[name="body"]').val() === '') {
        $.notify('warning', '内容がありません');
        return;
      }
      const data = {
        user_name: $('input[name="user_name"]').val() || this.name,
        public: $('input[name="public"]')[0].checked,
        title: $('input[name="title"]').val(),
        body: $('textarea[name="body"]').val(),
      };
      axios.post('/api/bbs/thread', data).then(() => {
        $('#new-thread-toggle').click();
        this.fetch(this.page);
        $('input[name="user_name"]').val(this.name);
        $('input[name="public"]')[0].checked = false;
        $('input[name="title"]').val('');
        $('textarea[name="body"]').val('');
        $.notify('clear');
        $.notify('success', '投稿しました');
      }).catch(() => {
        $.notify('danger', '投稿に失敗しました');
      });
    },
    search() {
      this.query = $('input[name="query"]').val();
      this.fetch(this.page);
    },
  },
  watch: {
    page(val) {
      this.fetch(val);
    },
  },
};
</script>
<style scoped>
#container {
  width: 85%;
  max-width: 680px;
}

.thread {
  white-space: pre-line;
  margin-bottom: 1.5em;
}
.thread .thread-info {
  width: 100%;
}
.thread .name {
  color: #040;
}
.thread .date {
  color: brown;
}
.thread .is-public {
  color: blue;
}
.thread .is-new {
  color: #f80;
}
</style>
