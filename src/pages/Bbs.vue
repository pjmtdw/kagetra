<template>
  <div class="container">
    <!-- スレッド作成/検索 -->
    <div class="d-flex mt-3">
      <b-button v-b-toggle.new_thread_form class="text-nowrap mx-1" variant="success" @click="formOpened = !formOpened">
        {{ formOpened ? 'キャンセル' : 'スレッド作成' }}
      </b-button>
      <b-input-group class="mr-1 ml-auto w-auto minw-50" expanded="default">
        <v-input v-model="searchQuery" @keydown.enter="search"/>
        <b-input-group-append>
          <b-button @click="search">検索</b-button>
        </b-input-group-append>
      </b-input-group>
    </div>
    <b-collapse id="new_thread_form" class="mt-2" @shown="$refs.titleInput.focus()">
      <b-card class="shadow-sm">
        <v-form ref="postThreadForm">
          <v-field label="名前" horizontal feedback="名前を入力してください">
            <v-input v-model="name" required/>
          </v-field>
          <v-field label="タイトル" feedback="タイトルを入力してください">
            <v-input ref="titleInput" v-model="title" required/>
          </v-field>
          <v-field label="内容" feedback="内容を入力してください">
            <v-textarea v-model="body" :autosize="{ minRows: 3 }" required/>
          </v-field>
          <div class="d-flex align-items-center">
            <b-form-checkbox v-model="publicThread" class="ml-auto">外部公開</b-form-checkbox>
            <b-button variant="success" class="ml-3" @click="postThread">投稿</b-button>
          </div>
        </v-form>
      </b-card>
    </b-collapse>
    <!-- スレッド -->
    <router-view ref="content"/>
  </div>
</template>
<script>
import { mapState } from 'vuex';
import { setBeforeUnload, unsetBeforeUnload } from '@/utils';
import { VField, VInput, VTextarea } from '@/basics';
import { VForm } from '@/components';

export default {
  components: {
    VField,
    VInput,
    VTextarea,
    VForm,
  },
  data() {
    return {
      // postThreadForm
      changed: false,
      formOpened: false,
      name: this.$store.state.auth.user ? this.$store.state.auth.user.name : null,
      title: null,
      body: null,
      publicThread: false,

      // search
      searchQuery: null,
    };
  },
  computed: {
    ...mapState('auth', [
      'user',
    ]),
  },
  watch: {
    body(val) {
      if (val.length > 50) this.changed = true;
    },
  },
  created() {
    setBeforeUnload('bbs', () => this.changed);
  },
  activated() {
    setBeforeUnload('bbs', () => this.changed);
  },
  deactivated() {
    unsetBeforeUnload('bbs');
  },
  destoryed() {
    unsetBeforeUnload('bbs');
  },
  methods: {
    postThread() {
      if (!this.$refs.postThreadForm.checkValidity()) return;
      const data = {
        name: this.name,
        title: this.title,
        body: this.body,
        public: this.publicThread,
      };
      this.$http.post('/bbs/thread', data).then(() => {
        this.name = this.user ? this.user.name : null;
        this.publicThread = false;
        this.title = null;
        this.body = null;
        this.changed = false;
        this.$refs.postThreadForm.reset();
        this.$refs.content.fetch();
      }).catch(() => {
        this.$notify.error('投稿に失敗しました');
      });
    },
    search() {
      this.$router.push({ query: { q: this.searchQuery } });
    },
  },
};
</script>
<style lang="scss" scoped>
.container {
  width: 100%;
  max-width: 1000px;
}
</style>
