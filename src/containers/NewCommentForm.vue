<template>
  <v-form ref="form" @keydown.shift.enter="postComment">
    <button class="btn btn-success" type="button" @click="postComment">投稿</button>
    <v-field feedback="名前を入力してください">
      <v-input v-model="name" class="w-auto my-2" placeholder="名前" required/>
    </v-field>
    <v-field feedback="内容を入力してください">
      <v-textarea ref="bodyInput" v-model="body" placeholder="内容" required/>
    </v-field>
  </v-form>
</template>
<script>
import { VForm } from '@/components';

export default {
  components: {
    VForm,
  },
  props: {
    url: {
      type: String,
      required: true,
    },
    threadId: {
      type: Number,
      default: null,
    },
  },
  data() {
    const userName = this.$store.state.auth.user ? this.$store.state.auth.user.name : null;
    return {
      userName,
      name: userName,
      body: null,
    };
  },
  methods: {
    postComment() {
      const { form } = this.$refs;
      if (!form.validate()) return;
      const data = {
        thread_id: this.threadId,
        user_name: this.name,
        body: this.body,
      };
      this.$http.post(this.url, data).then(() => {
        this.name = this.userName;
        this.body = null;
        form.reset();
        this.$emit('done', this.threadId);
      });
    },
    focus() {
      this.$refs.bodyInput.focus();
    },
  },
};
</script>
<style lang="scss" scoped>
</style>
