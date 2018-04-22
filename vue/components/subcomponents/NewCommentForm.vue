<template>
  <form :id="id" class="collapse" @submit.prevent>
    <input :value="threadId" type="hidden" name="thread_id">
    <button class="btn btn-success" type="button" @click="postComment">投稿</button>
    <input v-model="name" class="form-control w-auto my-2" type="text" name="user_name" placeholder="名前" required>
    <textarea v-model="body" class="form-control" name="body" :rows="rows" placeholder="内容" required/>
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
    threadId: {
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
    postComment() {
      if (this.threadId === null) {
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
        this.$emit('done', this.threadId);
      }).catch(() => {
        $.notify('danger', '投稿に失敗しました');
      });
    },
  },
};
</script>
<style lang="scss" scoped>
@import '../../sass/common.scss';
</style>
