<template>
  <nav class="navbar is-transparent">
    <div class="container position-relative">
      <div class="navbar-brand">
        <!-- <router-link to="/" id="logo" class="navbar-item has-text-weight-bold">
          景虎
        </router-link> -->
        <a class="navbar-burger burger" :class="{ 'is-active': showMenu }" @click="showMenu = !showMenu">
          <span/>
          <span/>
          <span/>
        </a>
      </div>
      <div v-if="$store.getters['screen/from']('desktop')" class="navbar-menu">
        <div class="navbar-start">
          <router-link to="/top" class="navbar-item is-tab" active-class="is-active">
            Top
          </router-link>
          <router-link to="/bbs" class="navbar-item is-tab" active-class="is-active">
            掲示板
          </router-link>
          <router-link to="/schedule" class="navbar-item is-tab" active-class="is-active">
            予定表
          </router-link>
          <router-link v-if="isAuthenticated" to="/result" class="navbar-item is-tab" active-class="is-active">
            大会結果
          </router-link>
        </div>
        <div class="navbar-end">
          <div v-if="isAuthenticated" class="navbar-item is-flex has-dropdown" :class="{ 'is-active': showUserInfo }">
            <a class="navbar-link" @click.stop="showUserInfo = !showUserInfo">
              <b-icon icon="user" :class="{ 'has-text-grey-light': !isAuthenticated }"/>
            </a>
            <div class="navbar-dropdown is-right" @click.stop>
              <div class="navbar-item flex-column align-items-start">
                <div class="has-text-grey-light">Signed in as</div>
                <div class="has-text-weight-semibold">{{ user.name }}</div>
              </div>
              <hr class="navbar-divider">
              <a class="navbar-item" @click="signOut">
                Sign out
              </a>
            </div>
          </div>
          <div v-else-if="$route.name !== 'Login'" class="navbar-item">
            <v-button type="info" :href="`/login?redirect=${this.$route.path}`">ログイン</v-button>
          </div>
        </div>
      </div>
      <template v-else>
        <transition name="menu">
          <div v-show="showMenu" class="navbar-menu is-active">
            <div class="navbar-start">
              <router-link to="/top" class="navbar-item" active-class="is-active">
                Top
              </router-link>
              <router-link to="/bbs" class="navbar-item" active-class="is-active">
                掲示板
              </router-link>
              <router-link to="/schedule" class="navbar-item" active-class="is-active">
                予定表
              </router-link>
              <router-link v-if="isAuthenticated" to="/result" class="navbar-item" active-class="is-active">
                大会結果
              </router-link>
            </div>
            <div class="navbar-end">
              <hr class="my-1">
              <div v-if="isAuthenticated" class="navbar-item is-flex has-dropdown" :class="{ 'is-active': showUserInfo }">
                <a class="navbar-link" @click.stop="showUserInfo = !showUserInfo">
                  <b-icon icon="user" :class="{ 'has-text-grey-light': !isAuthenticated }"/>
                </a>
                <div class="navbar-dropdown is-right" @click.stop>
                  <div class="navbar-item flex-column align-items-start">
                    <div class="has-text-grey-light">Signed in as</div>
                    <div class="has-text-weight-semibold">{{ user.name }}</div>
                  </div>
                  <hr class="navbar-divider">
                  <a class="navbar-item" @click="signOut">
                    Sign out
                  </a>
                </div>
              </div>
              <router-link v-else-if="$route.name !== 'Login'" to="/login" class="navbar-item">
                ログイン
              </router-link>
            </div>
          </div>
        </transition>
        <transition name="backdrop">
          <div v-show="showMenu" class="backdrop" @click.stop="showMenu = false"/>
        </transition>
      </template>
    </div>
  </nav>
</template>
<script>
import { VButton } from '../basics';

export default {
  components: {
    VButton,
  },
  data() {
    return {
      showMenu: null, // for mobile
      showUserInfo: false,
    };
  },
  computed: {
    isAuthenticated() {
      return this.$store.getters.isAuthenticated;
    },
    user() {
      return this.$store.getters.user;
    },
  },
  mounted() {
    document.addEventListener('click', this.hideUserInfo);
    this.$router.afterEach(() => {
      this.showMenu = false;
    });
  },
  beforeDestroy() {
    document.removeEventListener('click', this.hideUserInfo);
  },
  methods: {
    now() {
      return performance.now();
    },
    hideUserInfo() {
      this.showUserInfo = false;
    },
    signOut() {
      this.$store.dispatch('auth/logout').then(() => {
        this.hideUserInfo();
      });
    },
  },
};
</script>
<style lang="scss" scoped>
@import '../assets/scss/bulma_mixins';

nav.navbar {
  box-shadow: 0 .125rem .25rem rgba(0,0,0,.075);

  #logo:hover {
    color: inherit;
  }

  @include touch() {
    .navbar-menu {
      position: absolute;
      right: 0;
      height: fill-available;
      z-index: 20;
      max-width: 100vw;
      white-space: nowrap;
    }
    .menu-enter, .menu-leave-to {
      max-width: 0;
    }
    .menu-enter-active {
      transition: all .2s;
    }
    .menu-leave-active {
      transition: all .2s;
    }

    .backdrop {
      position: absolute;
      width: 100%;
      height: fill-available;
      z-index: 10;
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
