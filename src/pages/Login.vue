<template>
  <div class="container d-flex justify-content-center pt-5">
    <b-card v-if="loaded" class="login-form shadow-sm">
      <p class="h4 text-center">ログイン</p>
      <template v-if="step === 'shared'">
        <b-alert v-if="message_shared" show>
          {{ message_shared }}
        </b-alert>
        <v-field label="共通パスワード" :feedback="message_shared_password">
          <v-input v-model="shared_password" type="password" :state="message_shared_password ? false : null" autofocus @keydown.enter="submitSharedPassword"/>
        </v-field>
        <div class="d-flex">
          <b-button variant="primary" class="ml-auto" @click="submitSharedPassword">次へ</b-button>
        </div>
      </template>
      <template v-else>
        <b-alert v-if="message_user" show>
          {{ message_user }}
        </b-alert>
        <v-field label="ユーザー名">
          <filterable-select v-model="user" :data="users">
            <template #default="{ onInput, onFocus, onBlur }">
              <v-input v-model="userInput" placeholder="例)山田, やまだ" @input="onInput" @focus="onFocus" @blur="onBlur"/>
            </template>
            <template #item="{ item }">
              {{ item && item.name }}
            </template>
            <template #empty>
              名前を入力すると候補が表示されます
            </template>
          </filterable-select>
        </v-field>
        <v-field label="個人パスワード" feedback="個人パスワードが違います">
          <v-input v-model="password" type="password" :state="hasError ? false : null" @keydown.enter="login"/>
        </v-field>
        <div class="d-flex">
          <b-button variant="primary" class="ml-auto" @click="login">ログイン</b-button>
        </div>
      </template>
    </b-card>
  </div>
</template>
<script>
import { find } from 'lodash';
import { mapState, mapGetters } from 'vuex';
import { Status } from '../store/auth';
import { FilterableSelect } from '../components';

export default {
  components: {
    FilterableSelect,
  },
  data() {
    return {
      loaded: false,
      step: 'shared',

      message_shared: null,
      message_user: null,

      shared_password: null,
      message_shared_password: null,

      user: null,
      userInput: null,
      users: null,
      password: null,
    };
  },
  computed: {
    ...mapState('auth', [
      'status',
      'login_uid',
      'login_uname',
    ]),
    ...mapGetters('auth', ['hasError']),
  },
  watch: {
    user(newVal) {
      if (newVal) this.userInput = newVal.name;
    },
    userInput(newVal) {
      this.fetchUsernames(newVal);
    },
  },
  created() {
    if (this.status === Status.not_authorized) {
      this.step = 'shared';
      this.$http.get('/board_message/shared').then(({ data }) => {
        this.message_shared = data.message;
        this.loaded = true;
      });
      this.$http.get('/board_message/user').then(({ data }) => {
        this.message_user = data.message;
      });
    } else {
      this.step = 'user';
      this.$http.get('/board_message/user').then(({ data }) => {
        this.message_user = data.message;
        this.loaded = true;
      });
      if (this.login_uid) {
        this.user = {
          id: this.login_uid,
          name: this.login_uname,
        };
      }
    }
  },
  methods: {
    submitSharedPassword() {
      this.$store.dispatch('auth/request_shared', this.shared_password).then(() => {
        // success
        this.step = 'user';
      }).catch((err) => {
        // failure
        this.message_shared_password = '共通パスワードが違います';
        const d = Date.parse(err.response.data.updated_at);
        const dt = Math.floor(((new Date()).getTime() - d) / 3600000);
        if (dt < 24) {
          this.message_shared_password += `\nパスワードは${dt}時間前に変更されました`;
        } else if (dt < 90 * 24) {
          this.message_shared_password += `\nパスワードは${Math.floor(dt / 24)}日前に変更されました`;
        }
      });
    },
    fetchUsernames(input) {
      if (!input.length) {
        this.users = null;
        return;
      }
      this.$http.get('/auth/search', { params: { q: input } }).then(({ data }) => {
        this.users = data;
      }).catch((err) => {
        if (err.response.status === 401) {
          this.$message.warn('共通パスワードを入力してください');
          this.step = 'shared';
          this.$store.commit('auth/logout');
        }
      });
    },
    login() {
      // 一致するものがあれば選択(自動入力など補完を使わずに入力した場合に対応)
      const found = find(this.users, { name: this.userInput });
      if (found) {
        this.user = found;
      }

      if (this.user === null) {
        this.$message.error('ユーザー名が正しくありません');
        return;
      }

      const data = {
        id: this.user.id,
        password: this.password,
      };
      this.$store.dispatch('auth/request_user', data).then(() => {
        if (this.$route.query.redirect) {
          this.$router.push(this.$route.query.redirect);
        } else {
          this.$router.push('/');
        }
      });
    },
  },
};
</script>
<style lang="scss" scoped>
.login-form {
  max-width: 500px;
  width: 100%;
}
</style>
