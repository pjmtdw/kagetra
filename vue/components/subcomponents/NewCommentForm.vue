<template>
  <form :id="id" class="collapse" @submit.prevent @keydown.shift.enter="postComment" @input="changed = true">
    <input :value="threadId" type="hidden" name="thread_id">
    <button class="btn btn-success" type="button" @click="postComment">投稿</button>
    <div class="form-group">
      <input v-model="name" class="form-control w-auto my-2" type="text" name="user_name" placeholder="名前" required>
      <div class="invalid-feedback">名前を入力してください</div>
    </div>
    <div class="form-group">
      <textarea v-model="body" class="form-control" name="body" :rows="rows" placeholder="内容" required/>
      <div class="invalid-feedback">内容を入力してください</div>
    </div>
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
      changed: false,
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
    this.$_setBeforeUnload(() => this.changed);
  },
  methods: {
    postComment() {
      if (this.threadId === null) {
        this.$_notify('danger', '投稿できませんでした');
        return;
      }
      const $form = $(this.$el);
      if (!$form.check()) return;
      const data = $form.serializeObject();
      axios.post(this.url, data).then(() => {
        /* eslint-disable camelcase */
        this.name = g_user_name;
        this.body = '';
        this.$_notify('投稿しました');
        this.$emit('done', this.threadId);
      }).catch(() => {
        this.$_notify('danger', '投稿に失敗しました');
      });
    },
  },
};
</script>
<style lang="scss" scoped>
</style>
