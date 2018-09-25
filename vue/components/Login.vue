<template>
  <main id="container" class="mx-auto">
    <div class="bg-white border rounded shadow-sm p-4">
      <p class="h3 text-center">ログイン</p>
      <p v-if="mode === 'shared' && message_shared">{{ message_shared }}</p>
      <p v-if="mode !== 'shared' && message_user">{{ message_user }}</p>
      <template v-if="login_uid">
        <div class="form-group">
          <p>ユーザー名</p>
          <input class="form-control" type="text" :value="login_uname" readonly>
        </div>
        <div class="form-group">
          <label for="user_password_input">個人パスワード</label>
          <input id="user_password_input" ref="user_password_input" v-model="user_password" type="password"
                 class="form-control" :class="{'is-invalid': result_user === false}" @keydown.enter="submit_user_pass">
          <div class="invalid-feedback">
            個人パスワードが違います
          </div>
        </div>
        <div class="d-flex">
          <!-- <button class="btn btn-outline-primary" @click="select_other_uid">別ユーザでログイン</button> -->
          <a class="btn btn-outline-primary" href="/select_other_uid">別ユーザでログイン</a>
          <button class="btn btn-primary ml-auto" @click="submit_user_pass">ログイン</button>
        </div>
      </template>
      <template v-else-if="mode === 'shared'">
        <div class="form-group">
          <label for="shared_password_input">共通パスワード</label>
          <input id="shared_password_input" ref="shared_password_input" v-model="shared_password" type="password"
                 class="form-control" :class="{'is-invalid': result_shared === false}" @keydown.enter="submit_shared_pass">
          <div class="invalid-feedback">
            共通パスワードが違います
          </div>
        </div>
        <div class="d-flex">
          <button class="btn btn-primary ml-auto" @click="submit_shared_pass">次へ</button>
        </div>
      </template>
      <template v-else>
        <div class="form-group">
          <label>ユーザー名</label>
          <div class="form-inline">
            <select v-model="initial" class="form-control w-auto mr-2" @change="load_usernames">
              <option v-for="(initial, index) in initials" :key="initial" :value="index">
                {{ initial }}
              </option>
            </select>
            <select v-model="userid" class="form-control w-auto">
              <option v-for="u in usernames" :key="u.id" :value="u.id">
                {{ u.name }}
              </option>
            </select>
          </div>
        </div>
        <div class="form-group">
          <label for="user_password_input">個人パスワード</label>
          <input id="user_password_input" ref="user_password_input" v-model="user_password" type="password"
                 class="form-control" :class="{'is-invalid': result_user === false}" @keydown.enter="submit_user_pass">
          <div class="invalid-feedback">
            個人パスワードが違います
          </div>
        </div>
        <div class="d-flex">
          <button class="btn btn-primary ml-auto" @click="submit_user_pass">ログイン</button>
        </div>
      </template>
    </div>
  </main>
</template>
<script>
/* global CryptoJS, g_shared_salt, g_login_uid, g_login_uname */
// TODO: https化すればCryptoJS不要
export default {
  data() {
    return {
      mode: 'shared',
      login_uid: g_login_uid,
      login_uname: g_login_uname,
      message_shared: null,
      message_user: null,
      shared_password: null,
      result_shared: null,
      initial: null,
      initials: [],
      userid: null,
      usernames: [],
      user_password: null,
      result_user: null,
    };
  },
  created() {
    if (this.login_uid) {
      this.mode = 'user';
    } else {
      axios.get('/board_message/shared').then((res) => {
        this.message_shared = res.data.message;
      });
    }
    axios.get('/board_message/user').then((res) => {
      this.message_user = res.data.message;
    });
  },
  mounted() {
    if (this.login_uid) {
      this.$refs.user_password_input.focus();
    } else {
      this.$refs.shared_password_input.focus();
    }
  },
  methods: {
    pbkdf2_password(pass, salt) {
      return CryptoJS.PBKDF2(pass, salt, { keySize: 256 / 32, iterations: 100 }).toString(CryptoJS.enc.Base64);
    },
    hmac_password(pass, salt) {
      const secret = this.pbkdf2_password(pass, salt);
      const hmac = CryptoJS.algo.HMAC.create(CryptoJS.algo.SHA256, secret);
      const msg = CryptoJS.lib.WordArray.random(128 / 8).toString(CryptoJS.enc.Base64);
      hmac.update(msg);
      const hash = hmac.finalize().toString(CryptoJS.enc.Base64);
      return { hash, msg };
    },
    load_usernames() {
      axios.get(`/user/auth/list/${this.initial}`).then((res) => {
        this.usernames = res.data.list;
        if (!_.isEmpty(this.usernames)) {
          this.userid = this.usernames[0].id;
        }
      });
    },
    submit_shared_pass() {
      const data = this.hmac_password(this.shared_password, g_shared_salt);
      axios.post('/user/auth/shared', data).then((res) => {
        if (res.data.result === 'OK') {
          this.mode = 'user';
          axios.get('/initials').then((resp) => {
            this.initials = resp.data;
          });
          this.initial = 0;
          this.load_usernames();
        } else {
          // TODO: updated_atの処理
          this.result_shared = false;
        }
      });
    },
    submit_user_pass() {
      const userId = this.login_uid || this.userid;
      axios.get(`/user/auth/salt/${userId}`).then((res) => {
        const data = this.hmac_password(this.user_password, res.data.salt);
        data.user_id = userId;
        axios.post('/user/auth/user', data).then((resp) => {
          if (resp.data.result === 'OK') {
            location.href = '/top';
          } else {
            this.result_user = false;
          }
        });
      });
    },
  },
};
</script>
<style lang="scss" scoped>
#container {
  width: 85%;
  max-width: 500px;
  margin-top: 20vh;
}
</style>
