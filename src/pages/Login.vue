<template>
  <section class="section">
    <div class="container is-flex">
      <div v-if="loaded" class="box mx-auto">
        <p class="text-center is-size-4">ログイン</p>
        <template v-if="step === 'shared'">
          <div v-if="message_shared" class="notification shadow-sm">
            {{ message_shared }}
          </div>
          <v-field label="共通パスワード" :type="{ danger: hasError }" :message="message_shared_password">
            <v-input v-model="shared_password" type="password" autofocus @keydown.enter="submitSharedPassword"/>
          </v-field>
          <div class="is-flex">
            <v-button class="ml-auto" @click="submitSharedPassword">次へ</v-button>
          </div>
        </template>
        <template v-else>
          <div v-if="message_user" class="notification shadow-sm">
            {{ message_user }}
          </div>
          <v-field label="ユーザー名" :has-error="hasError && user === null" error-message="ユーザーが指定されていません">
            <filterable-select v-model="user" :data="users" field="name" :loading="isFetching" :fetch-method="fetchUsernames">
              <template #default="{ item }">
                {{ item && item.name }}
              </template>
              <template #loading>
                読込中...
              </template>
              <template #empty>
                名前を入力すると候補が表示されます
              </template>
              <template #none>
                候補が見つかりません
              </template>
            </filterable-select>
          </v-field>
          <v-field label="個人パスワード" :has-error="hasError && user !== null" error-message="個人パスワードが違います">
            <v-input v-model="password" type="password" @keydown.enter="login"/>
          </v-field>
          <div class="is-flex">
            <v-button class="ml-auto" @click="login">ログイン</v-button>
          </div>
        </template>
      </div>
    </div>
  </section>
</template>
<script>
import _ from 'lodash';
import { mapState, mapGetters } from 'vuex';
import { Status } from '../store/auth';
import { VField, VInput, VButton } from '../basics';
import { FilterableSelect } from '../components';

export default {
  components: {
    VField,
    VInput,
    VButton,
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
      isFetching: false,
      users: [],
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
      this.userInput = input;
      if (!input.length) {
        this.users = [];
        return;
      }
      this.isFetching = true;
      this.$http.get('/auth/search', { params: { q: input } }).then(({ data }) => {
        this.users = data;
      }).catch((err) => {
        if (err.response.status === 401) {
          this.$toast.open({
            type: 'is-warning',
            message: '共通パスワードを入力してください',
          });
          this.step = 'shared';
          this.$store.commit('auth/logout');
        }
      }).finally(() => {
        this.isFetching = false;
      });
    },
    login() {
      // 一致するものがあれば選択(自動入力など補完を使わずに入力した場合に対応)
      const found = _.find(this.users, { name: this.userInput });
      if (found) {
        this.user = found;
      }

      if (this.user === null) {
        this.$toast.open({
          message: 'ユーザー名を入力してください',
          type: 'is-danger',
          position: 'is-bottom',
        });
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
.box {
  max-width: 500px;
  width: 100%;
}
</style>
