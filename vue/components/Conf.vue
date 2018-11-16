<template>
  <main id="container" class="mx-auto">
    <div class="card mt-3">
      <div class="card-header">ユーザー設定</div>
      <div class="card-body">
        <label class="w-100">
          <span>掲示板の外部公開スレッドに書き込む際の名前</span>
          <input v-model="bbs_public_name" type="text" class="form-control">
        </label>
        <button class="btn btn-success" @click="saveUserConf">保存</button>
      </div>
    </div>
    <div class="card mt-3">
      <div class="card-header">パスワード変更</div>
      <div class="card-body">
        <label class="w-100">
          <span>現在のパスワード</span>
          <input v-model="current_password" type="password" class="form-control">
        </label>
        <label class="w-100">
          <span>新しいパスワード</span>
          <input v-model="new_password" type="password" class="form-control">
        </label>
        <label class="w-100">
          <span>新しいパスワード再入力</span>
          <input v-model="new_password_confirm" type="password" class="form-control">
        </label>
        <button class="btn btn-success" @click="savePassword">保存</button>
      </div>
    </div>
  </main>
</template>
<script>
/* global CryptoJS */
export default {
  data() {
    return {
      bbs_public_name: null,
      current_password: null,
      new_password: null,
      new_password_confirm: null,
      salt: null,
    };
  },
  created() {
    this.fetch();
  },
  methods: {
    fetch() {
      axios.get('/user_conf/etc').then((res) => {
        this.bbs_public_name = res.bbs_public_name;
      });
      axios.get('/user/mysalt').then((res) => {
        this.salt = res.data;
      });
    },
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
    saveUserConf() {
      const data = {
        bbs_public_name: this.bbs_public_name,
      };
      axios.post('/user_conf/etc', data).then(() => {
        this.$_notify('保存しました');
      }).catch(() => {
        this.$_notify('danger', '保存に失敗しました');
      });
    },
    savePassword() {
      if (_.isEmpty(this.new_password)) {
        this.$_notify('warning', '新しいパスワードが空です');
        return;
      }
      if (this.new_password !== this.new_password_confirm) {
        this.$_notify('warning', 'パスワードが一致しません');
        return;
      }
      const data = this.hmac_password(this.current_password, this.salt.salt_cur);
      axios.post('/user/confirm_password', data).then((res) => {
        if (res.data.result === 'OK') {
          const data2 = {
            hash: this.pbkdf2_password(this.new_password, this.salt.salt_new),
            salt: this.salt.salt_new,
          };
          axios.post('/user/change_password', data2).then((res2) => {
            if (res2.data.result === 'OK') {
              this.$_notify('保存しました');
            } else {
              this.$_notify('danger', '保存に失敗しました');
            }
          }).catch(() => {
            this.$_notify('danger', '保存に失敗しました');
          });
        } else {
          this.$_notify('danger', '現在のパスワードが違います');
        }
      });
    },
  },
};
</script>
<style lang="scss" scoped>
#container {
  width: 100%;
  max-width: 750px;
}
</style>
