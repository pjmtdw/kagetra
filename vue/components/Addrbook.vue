<template>
  <main id="container" class="mx-auto">
    <div v-if="!verified" class="mt-5 px-3">
      <label>名簿パスワードを入力</label>
      <div class="input-group">
        <input v-model="password" type="password" class="form-control" autofocus @keypress.enter="verify">
        <div class="input-group-append">
          <button class="btn btn-primary" @click="verify">OK</button>
        </div>
      </div>
    </div>
    <div v-else class="px-3 px-md-0">
      <select v-model="cond" class="custom-select mt-3 w-sm-25">
        <option v-for="c in conditions" :key="c.value" :value="c.value">{{ c.text }}</option>
      </select>
      <!-- >= 576px -->
      <div class="d-none d-sm-flex flex-row mt-3">
        <div class="user-list w-25">
          <div class="list-group">
            <a v-for="u in userList" :key="u.id" href="#" class="list-group-item list-group-item-action px-2 py-1" :class="{ active: userId === u.id }" @click.prevent="userId = u.id">
              {{ u.name }}
            </a>
          </div>
        </div>
        <UserDetail class="" :user-data="userData" :password="password" @done="fetchUser"/>
      </div>
      <!-- < 576px -->
      <div class="d-block d-sm-none mt-3">
        <select v-model="userId" class="custom-select">
          <option v-for="u in userList" :key="u.id" :value="u.id">{{ u.name }}</option>
        </select>
        <UserDetail class="mt-3" :user-data="userData" :password="password" @done="fetchUser"/>
      </div>
    </div>
  </main>
</template>
<script>
/* global g_addrbook_check_password */
import UserDetail from './subcomponents/UserDetail.vue';

export default {
  components: {
    UserDetail,
  },
  data() {
    return {
      password: '',
      verified: false,
      cond: 'recent',
      conditions: [
        { value: 'recent', text: '最近の更新' },
        { value: '0', text: 'あ行' },
        { value: '1', text: 'か行' },
        { value: '2', text: 'さ行' },
        { value: '3', text: 'た行' },
        { value: '4', text: 'な行' },
        { value: '5', text: 'は行' },
        { value: '6', text: 'ま行' },
        { value: '7', text: 'や行' },
        { value: '8', text: 'ら行' },
        { value: '9', text: 'わ行' },
        { value: '-1', text: 'その他' },
      ],
      userId: null,
      userIndex: null,
      userList: null,
      userData: {},
    };
  },
  watch: {
    cond() {
      this.fetch();
    },
    userId() {
      this.fetchUser();
    },
  },
  created() {
    document.addEventListener('keydown', (e) => {
      if (e.key === 'ArrowDown') {
        const index = _.findIndex(this.userList, { id: this.userId });
        if (index + 1 < this.userList.length) {
          this.userId = this.userList[index + 1].id;
          e.preventDefault();
        }
      } else if (e.key === 'ArrowUp') {
        const index = _.findIndex(this.userList, { id: this.userId });
        if (index - 1 >= 0) {
          this.userId = this.userList[index - 1].id;
          e.preventDefault();
        }
      }
    });
  },
  methods: {
    verify() {
      if (g_addrbook_check_password(this.password)) {
        this.verified = true;
        this.fetch();
      } else {
        this.$_notify('warning', '名簿パスワードが間違っています');
      }
    },
    fetch() {
      if (this.cond === 'recent') {
        axios.get('/addrbook/recent').then((res) => {
          const users = _.map(res.data.list, u => ({ id: u[0], name: u[1] }));
          // 自分を(recentにあれば)除く
          const myId = users[0].id;
          _.remove(users, u => u.id === myId && u.name !== '自分');
          this.userList = users;
          if (this.userList.length > 0) this.userId = this.userList[0].id;
        }).catch(this.$_makeOnFail('ユーザーリストの取得に失敗しました'));
      } else {
        axios.get(`/user/auth/list/${this.cond}`, { params: { all: true } }).then((res) => {
          this.userList = res.data.list;
          if (this.userList.length > 0) this.userId = this.userList[0].id;
        }).catch(this.$_makeOnFail('ユーザーリストの取得に失敗しました'));
      }
    },
    fetchUser() {
      axios.get(`/addrbook/item/${this.userId}`).then((res) => {
        this.userData = res.data;
      }).catch(this.$_makeOnFail('ユーザー情報の取得に失敗しました'));
    },
  },
};
</script>
<style lang="scss" scoped>
#container {
  width: 100%;
  max-width: 750px;
}

.user-list {
  height: 70vh;
  min-width: 25%;
  overflow-y: auto;
  -webkit-overflow-scrolling: touch;
}
</style>
