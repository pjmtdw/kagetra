<template>
  <b-navbar variant="light" class="shadow-sm" :class="{ 'py-0 pr-0': screenUntil('md') }">
    <b-container>
      <b-navbar-brand to="/">景虎</b-navbar-brand>
      <template v-if="screenFrom('lg')">
        <navbar-main-menu :pages="pages"/>
        <b-navbar-nav class="ml-auto">
          <!-- 通知 -->
          <b-nav-item-dropdown v-if="isAuthenticated" class="ml-auto" right>
            <template #button-content>
              <v-icon name="bell" size="lg"/>
            </template>
            <notifications/>
          </b-nav-item-dropdown>
          <!-- MainMenu -->
          <b-nav-item-dropdown v-if="isAuthenticated" right>
            <template #button-content>
              <v-icon name="user" size="lg"/>
            </template>
            <b-dropdown-text class="text-muted">{{ user.name }}</b-dropdown-text>
            <b-dropdown-divider/>
            <b-dropdown-item to="/user_conf">設定</b-dropdown-item>
            <b-dropdown-item @click="logout">ログアウト</b-dropdown-item>
          </b-nav-item-dropdown>
          <b-button v-else-if="$route.name !== 'Login'" to="/login" variant="outline-primary">
            ログイン
          </b-button>
        </b-navbar-nav>
      </template>
      <template v-else>
        <b-navbar-nav>
          <!-- 通知 -->
          <b-nav-item-dropdown v-if="isAuthenticated" class="d-flex align-items-center ml-auto" right no-caret>
            <template #button-content>
              <v-icon name="bell"/>
            </template>
            <notifications/>
          </b-nav-item-dropdown>
          <!-- MainMenu -->
          <navbar-toggle>
            <navbar-main-menu :pages="pages"/>
            <b-dropdown-divider/>
            <navbar-collapse v-if="isAuthenticated">
              <template #trigger>
                <span>{{ user.name }}</span>
              </template>
              <b-nav-item to="/user_conf">設定</b-nav-item>
              <b-nav-item @click="logout">ログアウト</b-nav-item>
            </navbar-collapse>
            <b-nav-item v-else-if="$route.name !== 'Login'" to="/login">
              ログイン
            </b-nav-item>
          </navbar-toggle>
        </b-navbar-nav>
      </template>
    </b-container>
  </b-navbar>
</template>
<script>
import { mapState, mapGetters } from 'vuex';
import Notifications from './Notifications.vue';
import NavbarToggle from './NavbarToggle.vue';
import NavbarCollapse from './NavbarCollapse.vue';
import NavbarMainMenu from './NavbarMainMenu.vue';

export default {
  components: {
    Notifications,
    NavbarToggle,
    NavbarCollapse,
    NavbarMainMenu,
  },
  data() {
    return {
      pages: [
        { path: 'top', title: 'TOP' },
        { path: 'bbs', title: '掲示板' },
        { path: 'schedule', title: '予定表' },
        { path: 'result', title: '大会結果', require: 'login' },
        { path: 'wiki', title: 'Wiki' },
        { path: 'album', title: 'アルバム', require: 'login' },
        { path: 'addrbook', title: '名簿', require: 'login' },
        {
          title: 'その他',
          children: [
            { path: 'admin', title: '管理画面', require: 'admin' },
            { path: 'login_log', title: 'ログイン履歴' },
          ],
        },
      ],
    };
  },
  computed: {
    ...mapState('auth', ['user']),
    ...mapGetters('auth', ['isAuthenticated']),
    ...mapGetters('screen', {
      screenUntil: 'until',
      screenFrom: 'from',
    }),
  },
  methods: {
    logout() {
      this.$store.dispatch('auth/logout').then(() => {
        this.$router.push('/login');
      });
    },
  },
};
</script>
