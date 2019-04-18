<template>
  <nav class="navbar is-transparent">
    <div class="container position-relative">
      <div class="navbar-brand">
        <!-- <router-link to="/" id="logo" class="navbar-item has-text-weight-bold">
          景虎
        </router-link> -->
        <template v-if="screenUntil('tablet')">
          <span class="navbar-item">{{ $route.meta.title }}</span>
          <!-- 通知 -->
          <notifications v-if="isAuthenticated" class="ml-auto"/>
          <!-- ハンバーガー -->
          <a class="navbar-burger burger" :class="{ 'is-active': showMenu, 'ml-0': isAuthenticated }" @click="showMenu = !showMenu">
            <span/>
            <span/>
            <span/>
          </a>
        </template>
      </div>

      <div v-if="screenFrom('desktop')" class="navbar-menu">
        <navbar-main-menu class="navbar-start" :pages="pages"/>
        <div class="navbar-end">
          <!-- 通知 -->
          <notifications v-if="isAuthenticated"/>
          <!-- ユーザー -->
          <navbar-dropdown v-if="isAuthenticated" position="right">
            <b-icon icon="user"/>
            <template #menu>
              <div class="navbar-item">
                <div class="has-text-weight-semibold cursor-default has-text-grey-light">{{ user.name }}</div>
              </div>
              <hr class="navbar-divider">
              <router-link to="user_conf" class="navbar-item">
                設定
              </router-link>
              <a class="navbar-item" @click="logout">
                ログアウト
              </a>
            </template>
          </navbar-dropdown>
          <div v-else-if="$route.name !== 'Login'" class="navbar-item">
            <v-button type="info" :href="`/login?redirect=${$route.path}`">ログイン</v-button>
          </div>
        </div>
      </div>

      <template v-else>
        <transition name="menu" @before-enter="toggleBodyScroll" @after-leave="toggleBodyScroll">
          <div v-show="showMenu" class="navbar-menu" :style="`height: calc(100vh - ${navHeight}px);`">
            <div class="navbar-start">
              <navbar-main-menu :pages="pages"/>
            </div>
            <div class="navbar-end">
              <hr v-if="isAuthenticated" class="my-1">
              <!-- ユーザー -->
              <navbar-dropdown v-if="isAuthenticated" type="collapse">
                <span>{{ user.name }}</span>
                <template #menu>
                  <router-link to="user_conf" class="navbar-item">
                    設定
                  </router-link>
                  <a class="navbar-item" @click="logout">
                    ログアウト
                  </a>
                </template>
              </navbar-dropdown>
              <router-link v-else-if="$route.name !== 'Login'" to="/login" class="navbar-item">
                ログイン
              </router-link>
            </div>
          </div>
        </transition>
        <transition name="backdrop">
          <div v-show="showMenu" class="backdrop" :style="`height: calc(100vh - ${navHeight}px);`" @click.stop="showMenu = false"/>
        </transition>
      </template>
    </div>
  </nav>
</template>
<script>
import { mapState, mapGetters } from 'vuex';
import { VButton } from '@/basics';
import Notifications from './Notifications.vue';
import NavbarDropdown from './NavbarDropdown.vue';
import NavbarMainMenu from './NavbarMainMenu.vue';

export default {
  components: {
    VButton,
    Notifications,
    NavbarDropdown,
    NavbarMainMenu,
  },
  data() {
    return {
      // for mobile
      navHeight: 0,
      showMenu: null,

      pages: [
        { dir: 'top', title: 'TOP' },
        { dir: 'bbs', title: '掲示板' },
        { dir: 'schedule', title: '予定表' },
        { dir: 'result', title: '大会結果', require: 'login' },
        { dir: 'wiki', title: 'Wiki' },
        { dir: 'album', title: 'アルバム', require: 'login' },
        { dir: 'addrbook', title: '名簿', require: 'login' },
        {
          title: 'その他',
          children: [
            { dir: 'admin', title: '管理画面', require: 'admin' },
            { dir: 'login_log', title: 'ログイン履歴' },
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
  mounted() {
    this.navHeight = this.$el.clientHeight;
    this.$router.afterEach(() => {
      this.showMenu = false;
    });
  },
  methods: {
    toggleBodyScroll() {
      if (document.documentElement.style.overflow === 'hidden') {
        document.documentElement.style.overflow = '';
        document.body.style.overflow = '';
      } else {
        document.documentElement.style.overflow = 'hidden';
        document.body.style.overflow = 'hidden';
      }
    },
    logout() {
      this.$store.dispatch('auth/logout').then(() => {
        this.$router.push('/login');
      });
    },
  },
};
</script>
<style lang="scss" scoped>
@import '../../assets/scss/bulma_mixins';

nav.navbar {
  box-shadow: 0 .125rem .25rem rgba(0,0,0,.075);

  #logo:hover {
    color: inherit;
  }

  @include touch() {
    .navbar-menu {
      display: block;
      position: absolute;
      right: 0;
      z-index: 40;
      width: 9rem;
      white-space: nowrap;
      overflow-y: auto;
    }
    .menu-enter, .menu-leave-to {
      width: 0;
    }
    .menu-enter-active, .menu-leave-active {
      transition: all .2s;
    }

    .backdrop {
      position: absolute;
      width: 100%;
      z-index: 30;
      background-color: rgba(0,0,0,.1);
    }
    .backdrop-enter, .backdrop-leave-to {
      opacity: 0;
    }
    .backdrop-enter-active, .backdrop-leave-active {
      transition: all .2s;
    }
  }
}
</style>
