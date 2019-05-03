<template>
  <div v-if="screenUntil('xs') && isAuthenticated">
    <b-tabs class="shedule-nav" align="around">
      <template #tabs>
        <b-nav-item to="/schedule" :active="$route.meta.page === 'main'">予定表</b-nav-item>
        <b-nav-item to="/schedule/ev_done" :active="$route.meta.page === 'ev_done'">過去の行事</b-nav-item>
      </template>
    </b-tabs>
    <router-view/>
  </div>
  <router-view v-else>
    <!-- for tablet, desktop -->
    <nav-button-group v-if="isAuthenticated" :links="links"/>
  </router-view>
</template>
<script>
import { NavButtonGroup } from '@/components';

export default {
  components: {
    NavButtonGroup,
  },
  computed: {
    links() {
      return [
        { text: '予定表', to: '/schedule', active: this.$route.meta.page === 'main' },
        { text: '過去の行事', to: '/schedule/ev_done', active: this.$route.meta.page === 'ev_done' },
      ];
    },
  },
};
</script>
<style lang="scss">
@import "../../assets/scss/helpers";

.shedule-nav {
  .nav-link {
    padding-top: .25rem;
    padding-bottom: .25rem;
    border-top: 0;
    border-left: 0;
    border-right: 0;
    color: $secondary;
    &:not(.active):hover {
      border-bottom-color: $dark;
    }
    &.active {
      background-color: transparent;
      border-color: transparent;
      border-bottom-color: $primary;
      color: $primary;
    }
  }
}
</style>
