<template>
  <main id="container" class="mx-auto">
    <!-- 新規作成 -->
    <div class="d-flex flex-row mt-3">
      <button class="btn btn-success ml-auto" @click="$router.push('/new')">新規作成</button>
    </div>
    <!-- タブ -->
    <nav class="mt-2">
      <div class="nav nav-tabs" id="nav-tab" role="tablist">
        <router-link :to="`/${pageId}`" class="nav-item nav-link border" :class="{ active: tab === 'main' }">
          本文
        </router-link>
        <router-link v-if="pageId > 0" :to="`/${pageId}/log`" class="nav-item nav-link border" :class="{ active: tab === 'log' }">
          履歴
        </router-link>
        <router-link v-if="pageId > 0" :to="`/${pageId}/attached`" class="nav-item nav-link border" :class="{ active: tab === 'attached' }">
          添付
          <span v-if="attached_count !== null">({{ attached_count }})</span>
        </router-link>
        <router-link v-if="pageId > 0" :to="`/${pageId}/comment`" class="nav-item nav-link border" :class="{ active: tab === 'comment' }">
          コメント
          <span v-if="comment_count !== null">({{ comment_count }}{{ has_new_comment ? ' new' : '' }})</span>
        </router-link>
      </div>
    </nav>
    <!-- タブの中 -->
    <div class="tab-content">
      <!-- 本文 -->
      <div id="nav-main" class="tab-pane border border-top-0 bg-white rounded-bottom p-2" :class="{ 'show active': tab === 'main' }">
        <div class="d-flex flex-row border-bottom pb-1 mb-2">
          <h3 class="mb-0">{{ title }}</h3>
          <button v-if="pageId > 0" class="btn btn-sm btn-outline-success ml-auto" @click="editing = !editing">{{ editing ? 'キャンセル' : '編集' }}</button>
        </div>
        <div v-if="!editing" class="wiki-content" v-html="html"/>
        <div v-else>
          <div class="d-flex flex-row">
            <button v-if="deletable" class="btn btn-danger" @click="deletePage">削除</button>
            <button class="btn btn-outline-info ml-auto" data-toggle="modal" data-target="#help_dialog">ヘルプ</button>
            <button class="btn btn-info ml-2" @click="showPreview">プレビュー</button>
            <button class="btn btn-success ml-2" @click="savePage">保存</button>
          </div>
          <div class="d-flex flex-row mt-3">
            <input v-model="edit.title" type="text" class="form-control w-75" placeholder="タイトル">
            <label class="ml-auto mb-0">
              <input v-model="edit.public" type="checkbox">
              外部公開
            </label>
          </div>
          <textarea v-model="edit.body" class="form-control my-3" :rows="rows" placeholder="本文"/>
          <div id="help_dialog" class="modal fade">
            <div class="modal-dialog modal-lg">
              <div class="modal-content">
                <div class="modal-header">
                  <h5 class="modal-title">Wikiの編集</h5>
                  <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                    <span aria-hidden="true">&times;</span>
                  </button>
                </div>
                <div class="modal-body">
                  このWikiは
                  <a href="http://ja.wikipedia.org/wiki/Markdown" target="_blank">Markdown記法</a>
                  で書くことができます．記法についての説明は前述のリンクに委ねるとして，ここではこのWiki独自の仕様について説明します．
                  ちなみに強制的に改行するには行末に空白2つ入れて下さい．
                  <hr>
                  このWikiでは任意のHTMLタグが使えます．また&lt;style&gt;を使うときは
                  <code>.wiki-content</code>
                  がページ内を示すセレクタです．
                  <hr>
                  Wiki内リンクは [[ ]] で囲みます．末尾に/log,/attached,/commentを付けるとそれぞれ履歴，添付，コメントへのリンクになります．
                  <div class="panel">
                    <code>
                      <div>[[ リンク先タイトル ]]</div>
                      <div>[[ リンク先タイトル | 表示される文字列 ]]</div>
                      <div>[[ リンク先タイトル/attached ]]</div>
                    </code>
                  </div>
                  <hr>
                  テーブルを記述するには下記のようにします．ハイフンは3つ以上必要です．
                  <div class="panel">
                    <code>
                      <div>| Item&nbsp;&nbsp; | Price |&nbsp;</div>
                      <div>| ------ | ----- |&nbsp;</div>
                      <div>| Apple&nbsp; | &nbsp;&nbsp;300 |&nbsp;</div>
                      <div>| Banana | &nbsp;&nbsp;400 |&nbsp;</div>
                    </code>
                  </div>
                  <hr>
                  <div>「外部公開」にチェックを入れるとそのページを公開できます．ただしコメント，添付ファイル，履歴は公開されません．</div>
                  <div>公開ページの一部を非公開にするには /* */ で囲みます．</div>
                  <div class="panel">
                    <code><div>この部分は公開 /* この部分は非公開 */</div></code>
                  </div>
                </div>
              </div>
            </div>
          </div>
          <div ref="previewDialog" class="modal fade">
            <div class="modal-dialog modal-lg">
              <div class="modal-content">
                <div class="modal-header">
                  <h5 class="modal-title">プレビュー</h5>
                  <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                    <span aria-hidden="true">&times;</span>
                  </button>
                </div>
                <div class="modal-body p-2">
                  <div class="wiki-content" v-html="previewHtml"/>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
      <!-- 履歴 -->
      <div v-if="pageId > 0" id="nav-log" class="tab-pane border border-top-0 bg-white rounded-bottom p-2" :class="{ 'show active': tab === 'log' }">
        <div class="d-flex flex-row">
          <button class="btn btn-primary" :disabled="logPage <= 1" @click="logPage -= 1" >Previous</button>
          <button class="btn btn-primary ml-auto" :disabled="!logData.next_page" @click="logPage += 1">Next</button>
        </div>
        <div>
          <div v-for="log in logData.list" :key="log.revision">
            <hr>
            <div>
              <span class="font-weight-bold">[{{ log.revision }}]</span>
              <span>{{ log.user_name }}</span>
              <span class="date">@{{ log.date }}</span>
            </div>
            <div class="log-content pre" v-html="log.html"/>
          </div>
        </div>
        <div class="d-flex flex-row mt-3">
          <button class="btn btn-primary" :disabled="logPage <= 1" @click="logPage -= 1" >Previous</button>
          <button class="btn btn-primary ml-auto" :disabled="!logData.next_page" @click="logPage += 1">Next</button>
        </div>
      </div>
      <!-- 添付 -->
      <div v-if="pageId > 0" id="nav-attached" class="tab-pane border border-top-0 bg-white rounded-bottom p-2" :class="{ 'show active': tab === 'attached' }">
        <button class="btn btn-success" data-toggle="modal" data-target="#attach_file_dialog">ファイル添付</button>
        <div id="attach_file_dialog" class="modal fade">
          <div class="modal-dialog">
            <div class="modal-content">
              <div class="modal-header">
                <h5 class="modal-title">ファイル添付</h5>
                <button type="button" class="close" data-dismiss="modal">
                  <span>&times;</span>
                </button>
              </div>
              <div class="modal-body p-2">
                <FilePost :id="pageId" namespace="wiki" @done="submitFileDone"/>
              </div>
            </div>
          </div>
        </div>
        <nav v-if="attachData.pages > 1" class="mt-2 pl-2">
          <ul class="pagination justify-content-center">
            <li v-for="p in attachData.pages" :key="p" class="page-item" :class="{'active': p == attachPage}">
              <a class="page-link" href="#" @click.prevent="attachPage = p">
                {{ p }}
              </a>
            </li>
          </ul>
        </nav>
        <FileList namespace="wiki" :id="pageId" :file-list="attachData.list" class="mt-3" @done="submitFileDone"/>
        <nav v-if="attachData.pages > 1" class="mt-2 pl-2">
          <ul class="pagination justify-content-center">
            <li v-for="p in attachData.pages" :key="p" class="page-item" :class="{'active': p == attachPage}">
              <a class="page-link" href="#" @click.prevent="attachPage = p">
                {{ p }}
              </a>
            </li>
          </ul>
        </nav>
      </div>
      <!-- コメント -->
      <div v-if="pageId > 0" id="nav-comment" class="tab-pane border border-top-0 bg-white rounded-bottom" :class="{ 'show active': tab === 'comment' }">
        <div class="d-flex justify-content-between align-items-center">
          <h5 class="m-2">
            <strong>{{ thread_name }}</strong>
          </h5>
          <button id="new_comment_toggle" class="btn btn-success m-2" data-toggle="collapse" href="#new_comment_form" @click="toggleNewComment">
            書き込む
          </button>
        </div>
        <NewCommentForm id="new_comment_form" class="mx-3 mb-3 mt-2" url="/wiki/comment/item" :thread-id="pageId" @done="postDone"/>
        <nav v-if="commentPages > 1" class="mt-2 pl-2">
          <ul class="pagination justify-content-center">
            <li v-for="p in commentPages" :key="p" class="page-item" :class="{'active': p == commentPage}">
              <a class="page-link" href="#" @click.prevent="commentPage = p">
                {{ p }}
              </a>
            </li>
          </ul>
        </nav>
        <CommentList :comments="commentList" url="/wiki/comment/item" item-class="px-2 py-1" @done="fetchComment"/>
        <nav v-if="commentPages > 1" class="mt-2 pl-2">
          <ul class="pagination justify-content-center">
            <li v-for="p in commentPages" :key="p" class="page-item" :class="{'active': p == commentPage}">
              <a class="page-link" href="#" @click.prevent="commentPage = p">
                {{ p }}
              </a>
            </li>
          </ul>
        </nav>
      </div>
    </div>
  </main>
</template>
<script>
import CommentList from './subcomponents/CommentList.vue';
import FilePost from './subcomponents/FilePost.vue';
import FileList from './subcomponents/FileList.vue';

export default {
  components: {
    CommentList,
    FilePost,
    FileList,
  },
  props: {
    pageId: {
      type: Number,
      required: true,
    },
    tab: {
      type: String,
      default: 'main',
    },
  },
  data() {
    return {
      title: null,
      html: null,
      public: null,
      deletable: null,
      revision: null,
      editing: false,
      edit: {},
      previewHtml: null,
      // log
      logData: {},
      logPage: 1,
      // attached
      attached_count: null,
      attachData: {},
      attachPage: 1,
      // comment
      thread_name: null,
      comment_count: null,
      has_new_comment: null,
      commentPage: 1,
      commentPages: null,
      commentList: [],
    };
  },
  computed: {
    rows() {
      if (_.isNil(this.edit.body)) return 4;
      return _.max([this.edit.body.split('\n').length, 4]);
    },
  },
  watch: {
    pageId() {
      this.fetch();
      if (this.pageId > 0) {
        this.fetchLog();
        this.fetchAttached();
        this.fetchComment();
      }
    },
    logPage() {
      this.fetchLog();
    },
    attachPage() {
      this.fetchAttached();
    },
    commentPage() {
      this.fetchComment();
    },
    html() {
      this.$nextTick(() => {
        _.each($('a.link-page', this.$el), (e) => {
          e.setAttribute('href', `/wiki#${this.getLink(e)}`);
        });
        _.each($('a.goto-page', this.$el), (e) => {
          e.setAttribute('href', `/wiki#${this.getLink(e)}`);
        });
      });
    },
    editing(toVal) {
      if (toVal) {
        this.fetchEdit();
        this.$set(this.edit, 'title', this.title);
        this.$set(this.edit, 'public', this.public);
      }
    },
  },
  created() {
    this.fetch();
    if (this.pageId > 0) {
      this.fetchLog();
      this.fetchAttached();
      this.fetchComment();
    } else {
      $(document).on('click', 'a.link-page', (e) => {
        this.$router.push(this.getLink(e.target));
        e.preventDefault();
      });
    }
    $(document).on('click', 'a.link-page', (e) => {
      this.$router.push(this.getLink(e.target));
      e.preventDefault();
    });
  },
  methods: {
    fetch() {
      axios.get(`/wiki/item/${this.pageId > 0 ? this.pageId : `all?page=${-this.pageId}`}`).then((res) => {
        _.each(_.keys(res.data), (k) => {
          this[k] = res.data[k];
        });
      });
    },
    fetchEdit() {
      axios.get(`/wiki/item/${this.pageId}?edit=true`).then((res) => {
        this.$set(this.edit, 'body', res.data.body);
      });
    },
    getLink(elem) {
      if (elem.getAttribute('data-link-id')) {
        return `/${elem.getAttribute('data-link-id')}${elem.getAttribute('data-link-extra') || ''}`;
      }
      return `/all?page=${elem.getAttribute('data-page-num')}`;
    },
    showPreview() {
      axios.post('/wiki/preview', { body: this.edit.body }).then((res) => {
        this.previewHtml = res.data.html;
        $(this.$refs.previewDialog).modal('show');
      });
    },
    savePage() {
      const data = {
        id: this.pageId,
        body: this.edit.body,
        revision: this.revision + 1,
      };
      if (this.is_public !== this.edit.public) data.public = this.edit.public;
      if (this.title !== this.edit.title) data.title = this.edit.title;
      axios.put(`/wiki/item/${this.pageId}`, data).then(() => {
        this.editing = false;
        this.fetch();
      }).catch(this.$_makeOnFail('保存に失敗しました'));
    },
    deletePage() {
      axios.delete(`/wiki/item/${this.pageId}`).then(() => {
        this.editing = false;
        this.$router.push('/');
      }).catch(this.$_makeOnFail('削除に失敗しました'));
    },

    // 履歴
    fetchLog() {
      const data = this.logPage === 1 ? null : { page: this.logPage };
      axios.get(`/wiki/log/${this.pageId}`, { params: data }).then((res) => {
        this.logData = res.data;
      });
    },

    // 添付ファイル
    fetchAttached() {
      const data = this.attachPage === 1 ? null : { page: this.attachPage };
      axios.get(`/wiki/attached_list/${this.pageId}`, { params: data }).then((res) => {
        this.attachData = res.data;
      });
    },
    formatSize(size) {
      if (size < 1024) return `${size} bytes`;
      else if (size < 1024 * 1024) return `${_.floor(size / 1024)} KB`;
      return `${_.floor(size / (1024 * 1024))} KB`;
    },
    submitFileDone() {
      this.fetchAttached();
      $('#attach_file_dialog').modal('hide');
    },

    // コメント
    fetchComment() {
      const data = this.commentPage === 1 ? null : { page: this.commentPage };
      axios.get(`/wiki/comment/list/${this.pageId}`, data).then((res) => {
        _.each(_.keys(res.data), (k) => {
          if (k === 'list') this.commentList = res.data.list;
          else if (k === 'cur_page') this.commentPage = res.data.cur_page;
          else if (k === 'pages') this.commentPages = res.data.pages;
          else this[k] = res.data[k];
        });
      }).catch(this.$_makeOnFail('取得に失敗しました'));
    },
    toggleNewComment(e) {
      const $toggle = $(e.target);
      $toggle.toggleBtnText('書き込む', 'キャンセル');
      $toggle.toggleClass('btn-success');
      $toggle.toggleClass('btn-outline-success');
    },
    postDone() {
      $('#new_comment_toggle').click();
      this.fetchComment();
    },
  },
};
</script>
<style lang="scss" scoped>
#container {
  width: 100%;
  max-width: 750px;
}

.nav-tabs a {
  &:not(.active) {
    background-color: #f8f9fa;
  }
  &.active {
    border-bottom: 0!important;
  }
}

.date {
  color: maroon;
}

.log-content {
  overflow-x: scroll;
}

#nav-attached {
  overflow-x: scroll;
  @media screen and (min-width: 576px) {
    .date, .size {
      white-space: nowrap;
    }
  }
}
</style>
<style lang="scss">
@import '../sass/wiki.scss';
</style>
