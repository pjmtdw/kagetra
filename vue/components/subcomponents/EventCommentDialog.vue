<template>
  <div class="modal fade" tabindex="-1" role="dialog">
    <div class="modal-dialog modal-lg" role="document">
      <div v-if="id !== null" class="modal-content">
        <div class="modal-header d-flex align-items-center">
          <h5 class="modal-title">{{ name }}</h5>
          <button ref="new_comment_toggle" class="btn btn-success ml-auto" data-toggle="collapse" data-target="#new-comment-form" @click="toggleNewComment">
            書き込む
          </button>
          <button class="btn btn-info ml-2" @click="openInfo">情報</button>
          <button type="button" class="close ml-1" data-dismiss="modal">&times;</button>
        </div>
        <div class="modal-body">
          <NewCommentForm id="new-comment-form" class="" url="/event/comment/item" :thread-id="id" @done="postDone"/>
          <nav v-if="pages > 1" class="pl-2">
            <ul class="pagination">
              <li v-for="p in pages" :key="p" class="page-item" :class="{'active': p == page}">
                <a class="page-link" href="#" @click.prevent="page = p">
                  {{ p }}
                </a>
              </li>
            </ul>
          </nav>
          <CommentList :comments="comments" url="/event/comment/item" @done="fetch"/>
        </div>
      </div>
    </div>
  </div>
</template>
<script>
import CommentList from './CommentList.vue';
import NewCommentForm from './NewCommentForm.vue';

export default {
  components: {
    CommentList,
    NewCommentForm,
  },
  data() {
    return {
      $dialog: null,
      id: null,
      page: 1,
      pages: 1,
      name: null,
      comments: [],
    };
  },
  watch: {
    page() {
      this.fetch();
    },
  },
  mounted() {
    this.$dialog = $(this.$el);
    this.$dialog.on('shown.bs.modal', () => $('body').addClass('modal-open'));
  },
  methods: {
    open(id) {
      this.id = id;
      this.$dialog.modal('show');
      this.fetch();
    },
    fetch() {
      const data = {};
      if (this.page > 1) data.page = this.page;
      axios.get(`/event/comment/list/${this.id}`, { params: data }).then((res) => {
        this.name = res.data.thread_name;
        this.pages = res.data.pages;
        this.comments = res.data.list;
      });
    },
    toggleNewComment(e) {
      const $toggle = $(e.target);
      $toggle.toggleBtnText('書き込む', 'キャンセル');
      $toggle.toggleClass('btn-success');
      $toggle.toggleClass('btn-outline-success');
    },
    postDone() {
      this.$refs.new_comment_toggle.click();
      this.fetch();
      this.$emit('done');
    },

    openInfo() {
      this.$dialog.modal('hide');
      this.$emit('openinfo', this.id);
    },
  },
};
</script>
