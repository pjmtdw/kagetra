<template>
  <div class="container">
    <!-- スレッド作成/検索 -->
    <div class="d-flex mt-3">
      <b-button v-b-toggle.new_thread_form class="text-nowrap mr-1" variant="success" @click="formOpened = !formOpened">
        {{ formOpened ? 'キャンセル' : 'スレッド作成' }}
      </b-button>
      <b-input-group class="shadow-sm ml-auto w-auto minw-50">
        <v-input v-model="searchQuery" @keydown.enter="search"/>
        <b-input-group-append>
          <b-button @click="search">検索</b-button>
        </b-input-group-append>
      </b-input-group>
    </div>
    <b-collapse id="new_thread_form" class="mt-2" @shown="$refs.titleInput.focus()">
      <b-card class="shadow-sm">
        <v-form ref="newThreadForm">
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
import { VForm } from '@/components';

export default {
  components: {
    VForm,
  },
  data() {
    return {
      // newThreadForm
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
      else if (val.length < 20) this.changed = false;
    },
  },
  created() {
    setBeforeUnload('bbs', () => this.changed);
  },
  deactivated() {
    this.changed = false;
  },
  destoryed() {
    unsetBeforeUnload('bbs');
  },
  methods: {
    postThread() {
      if (!this.$refs.newThreadForm.validate()) return;
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
        this.$refs.newThreadForm.reset();
        this.$refs.content.fetch();
      }).catch(() => {
        this.$message.error('投稿に失敗しました');
      });
    },
    search() {
      if (this.searchQuery === '') this.$router.push('/bbs');
      else this.$router.push({ path: '/bbs', query: { q: this.searchQuery } });
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
