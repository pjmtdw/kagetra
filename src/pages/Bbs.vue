<template>
  <div class="container">
    <!-- スレッド作成/検索 -->
    <div class="is-flex mt-3">
      <v-button class="mx-1" type="success" @click="formOpened = !formOpened">
        {{ formOpened ? 'キャンセル' : 'スレッド作成' }}
      </v-button>
      <input-group class="mr-1 ml-auto minw-50" expanded="default">
        <v-input v-model="searchQuery" @keydown.enter="search"/>
        <template #append>
          <v-button @click="search">検索</v-button>
        </template>
      </input-group>
    </div>
    <collapse class="mt-2" :open.sync="formOpened" animation="slide" @shown="$refs.titleInput.focus()">
      <v-form ref="postThreadForm" class="box">
        <v-field label="名前" horizontal error-message="名前を入力してください">
          <v-input v-model="name" required/>
        </v-field>
        <v-field label="タイトル" error-message="タイトルを入力してください">
          <v-input ref="titleInput" v-model="title" required/>
        </v-field>
        <v-field label="内容" error-message="内容を入力してください">
          <v-textarea v-model="body" :autosize="{ minRows: 3 }" required/>
        </v-field>
        <div class="is-flex">
          <v-checkbox v-model="publicThread" class="ml-auto">外部公開</v-checkbox>
          <v-button class="ml-3" type="success" @click="postThread">投稿</v-button>
        </div>
      </v-form>
    </collapse>
    <!-- スレッド -->
    <router-view ref="content"/>
  </div>
</template>
<script>
import { mapState } from 'vuex';
import { setBeforeUnload, unsetBeforeUnload } from '@/utils';
import { VButton, VField, VInput, VTextarea, VCheckbox } from '@/basics';
import { VForm, Collapse, InputGroup } from '@/components';

export default {
  components: {
    VButton,
    VField,
    VInput,
    VTextarea,
    VCheckbox,
    VForm,
    Collapse,
    InputGroup,
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
