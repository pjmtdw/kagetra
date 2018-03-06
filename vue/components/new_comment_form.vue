<template>
  <form :id="id" class="collapse" @submit.prevent>
    <input type="hidden" name="thread_id" :value="thread_id">
    <button class="btn btn-success" type="button" @click="post_comment">投稿</button>
    <input class="form-control w-auto my-2" type="text" name="user_name" placeholder="名前" v-model="name" required>
    <textarea class="form-control" name="body" :rows="rows" placeholder="内容" v-model="body" required/>
  </form>
</template>
<script>
/* global g_user_name */
export default {
  props: {
    id: {
      type: String,
      default: null,
    },
    url: {
      type: String,
      default: null,
    },
    thread_id: {
      type: Number,
      default: null,
    },
  },
  data() {
    return {
      name: g_user_name,
      body: '',
    };
  },
  computed: {
    rows() {
      return _.max([this.body.split('\n').length, 4]);
    },
  },
  mounted() {
    const $this = $(this.$el);
    $this.on('shown.bs.collapse', () => {
      $this.find('textarea').focus();
    });
  },
  methods: {
    post_comment() {
      if (this.thread_id === null) {
        $.notify('danger', '投稿できませんでした');
        return;
      }
      const $form = $(this.$el);
      if (!$form.check()) {
        if (!this.name) $.notify('warning', '名前を入力してください');
        if (!this.body) $.notify('warning', '内容を入力してください');
        return;
      }
      const data = $form.serializeObject();
      axios.post(this.url, data).then(() => {
        /* eslint-disable camelcase */
        this.name = g_user_name;
        this.body = '';
        $form.removeClass('was-validated');
        $.notify('success', '投稿しました');
        this.$emit('done', this.thread_id);
      }).catch(() => {
        $.notify('danger', '投稿に失敗しました');
      });
    },
  },
};
</script>
<style lang="scss" scoped>
@import '../sass/common.scss';
</style>
