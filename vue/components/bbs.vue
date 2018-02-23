<template>
  <div id="container" class="mx-auto">
    <div class="d-flex flex-row">
      <button id="new-thread-toggle" class="btn btn-success m-2" data-toggle="collapse" href="#new-thread-form" aria-expanded="false" aria-controls="new-thread-form">
        スレッド作成
      </button>
      <form id="search-form" class="ml-auto" @submit.prevent="search">
        <div class="form-group input-group my-2">
          <input class="form-control" name="query" type="text" placeholder="検索文字列">
          <div class="input-group-append">
            <button class="btn btn-secondary" type="button" @click="search">検索</button>
          </div>
        </div>
      </form>
    </div>
    <form id="new-thread-form" class="collapse my-1" @submit.prevent>
      <div class="card card-block">
        <div class="form-group m-2">
          <button class="btn btn-outline-success" type="button" @click="create_new_thread">送信</button>
        </div>
        <div class="form-group form-inline mx-3">
          <label>
            名前
            <input class="form-control ml-md-2" type="text" name="user_name" placeholder="名前" :value="name">
          </label>
          <div class="form-check ml-5">
            <label class="form-check-label">
              <input class="form-check-input" type="checkbox" name="public">
              外部公開
            </label>
          </div>
        </div>
        <div class="form-group mx-3">
          <label style="width:100%;">
            タイトル
            <input class="form-control" type="text" name="title" placeholder="タイトル">
          </label>
        </div>
        <div class="form-group mx-3">
          <label style="width:100%;">
            内容
            <textarea class="form-control" name="body" rows="4" placeholder="内容"/>
          </label>
        </div>
      </div>
    </form>
    <ul class="pagination my-2 justify-content-center">
      <li v-for="i in pages" class="page-item" :class="{ active: page == i }" :key="i">
        <router-link class="page-link" :to="i.toString()">{{ i }}</router-link>
      </li>
    </ul>
    <div class="card thread" :class="{'border-primary': thread.public, 'private': !thread.public}" v-for="thread in threads" :key="thread.id">
      <div class="card-header h5">
        <span class="h6">{{ thread.title }}</span>
        <span v-if="thread.public" class="float-right badge badge-primary mx-1">外部公開</span>
        <span v-if="thread.has_new_comment" class="float-right badge badge-info mx-1">新着あり</span>
      </div>
      <ul class="list-group list-group-flush">
        <li class="list-group-item px-3" v-for="item in thread.items" :key="item.id">
          <div class="thread-info d-flex">
            <span class="name">{{ item.user_name }}</span>＠<span class="date mr-auto">{{ item.date }}</span>
            <h6 v-if="item.is_new" class="align-self-center"><span class="badge badge-info mx-1">New</span></h6>
            <button class="edit-item btn btn-success btn-sm" v-if="item.editable" :data-id="item.id" aria-expanded="false">
              編集
            </button>
          </div>
          <div :id="'item' + item.id" class="thread-body pl-1">{{ item.body }}</div>
          <form :id="'editItem' + item.id" class="mt-3 d-none" v-if="item.editable" :data-id="item.id" @submit.prevent>
            <button class="btn btn-outline-success" type="button" @click="edit_item">送信</button>
            <button class="btn btn-outline-danger" type="button" @click="delete_item">削除</button>
            <input class="form-control my-2" type="text" name="user_name" placeholder="名前" :value="item.user_name">
            <textarea class="form-control" name="body" rows="4" placeholder="内容"/>
          </form>
        </li>
      </ul>
      <div>
        <button class="new-item-toggle btn btn-success mt-3 mb-2 ml-3" data-toggle="collapse" :href="'#new-item-form' + thread.id" aria-expanded="false" :aria-controls="'new-item-form' + thread.id">
          書き込み
        </button>
        <form :id="'new-item-form' + thread.id" class="collapse ml-3 mb-3" @submit.prevent>
          <input type="hidden" name="thread_id" :value="thread.id">
          <button class="btn btn-outline-success" type="button" @click="create_new_item">送信</button>
          <input class="form-control my-2" type="text" name="user_name" placeholder="名前" :value="name">
          <textarea class="form-control" name="body" rows="4" placeholder="内容"/>
        </form>
      </div>
    </div>
  </div>
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
      name: g_user_name,
      query: '',
    };
  },
  watch: {
    page(val) {
      this.fetch(val);
    },
  },
  created() {
    this.fetch(this.page);
  },
  mounted() {
    const $toggle = $('#new-thread-toggle');
    $toggle.click(() => {
      $toggle.html($toggle.attr('aria-expanded') === 'true' ? 'スレッド作成' : 'キャンセル');
    });
    // まだDOMが生成されていない部分なので親要素に対して設定
    $('#container').on('click', '.new-item-toggle', (evt) => {
      const $itemToggle = $(evt.target);
      const expanded = $itemToggle.attr('aria-expanded') === 'true';
      $itemToggle.html(expanded ? '書き込み' : 'キャンセル');
    });
    $('#container').on('click', '.edit-item', (evt) => {
      const $editToggle = $(evt.target);
      const id = $editToggle.attr('data-id');
      const $item = $(`#item${id}`);
      const $edit = $(`#editItem${id}`);
      const expanded = $editToggle.attr('aria-expanded') === 'true';
      $editToggle.html(expanded ? '編集' : 'キャンセル');
      $editToggle.attr('aria-expanded', expanded ? 'false' : 'true');
      $item.toggleClass('d-none');
      $edit.toggleClass('d-none');
      if (!expanded) {
        $('textarea', $edit).val($item.html().trim());
        $('textarea', $edit).trigger('input');
      }
    });
    // textareaの行数を内容に合わせて変更
    $('#container').on('input', 'textarea', (evt) => {
      const $tgt = $(evt.target);
      $tgt.attr('rows', _.max([$tgt.val().split('\n').length, 4]));
    });
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
        $.notify('danger', '投稿の取得に失敗しました');
      });
    },
    create_new_thread() {
      if ($('#new-thread-form input[name="title"]').val() === '') {
        $.notify('warning', 'タイトルを入力してください');
        return;
      }
      if ($('#new-thread-form textarea[name="body"]').val() === '') {
        $.notify('warning', '内容がありません');
        return;
      }
      const data = $('#new-thread-form').serializeObject();
      data.public = $('#new-thread-form input[name="public"]')[0].checked;
      axios.post('/api/bbs/thread', data).then(() => {
        $('#new-thread-form input[name="user_name"]').val(this.name);
        $('#new-thread-form input[name="public"]')[0].checked = false;
        $('#new-thread-form input[name="title"]').val('');
        $('#new-thread-form textarea[name="body"]').val('');
        $('#new-thread-toggle').click();
        $.notify('clear');
        $.notify('success', '投稿しました');
        this.fetch(this.page);
      }).catch(() => {
        $.notify('danger', '投稿に失敗しました');
      });
    },
    search() {
      this.query = $('#search-form input[name="query"]').val();
      this.fetch(this.page);
    },
    edit_item(evt) {
      const $form = $(evt.target).parent();
      const id = Number($form.attr('data-id'));
      const $toggle = $(`button[data-id="${id}"]`);
      const data = $form.serializeObject();
      axios.put(`/api/bbs/item/${id}`, data).then(() => {
        $toggle.click();
        $.notify('clear');
        $.notify('success', '更新しました');
        this.fetch(this.page);
      }).catch(() => {
        $.notify('danger', '更新に失敗しました');
      });
    },
    delete_item(evt) {
      const $form = $(evt.target).parent();
      const id = Number($form.attr('data-id'));
      axios.delete(`/api/bbs/item/${id}`).then(() => {
        $.notify('clear');
        $.notify('success', '削除しました');
        this.fetch(this.page);
      }).catch(() => {
        $.notify('danger', '削除に失敗しました');
      });
    },
    create_new_item(evt) {
      const $form = $(evt.target).parent();
      const data = $form.serializeObject();
      const $toggle = $(`button[href="#new-item-form${data.thread_id}"]`);
      axios.post('/api/bbs/item', data).then(() => {
        $('input[name="user_name"]', $form).val(this.name);
        $('textarea[name="body"]', $form).val('');
        $toggle.click();
        $.notify('clear');
        $.notify('success', '投稿しました');
        this.fetch(this.page);
      }).catch(() => {
        $.notify('danger', '投稿に失敗しました');
      });
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

.thread {
  white-space: pre-line;
  margin-bottom: 1.5em;

  &.private {
    border: 1px solid green;
    background-color: #FFD;
    li {
      background-color: #FFD;
    }
  }

  .thread-info {
    width: 100%;
  }

  .name {
    color: #040;
  }

  .date {
    color: brown;
  }
}

.form-inline .form-check {
  width: auto;
}
</style>
