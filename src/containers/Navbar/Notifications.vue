<template>
  <navbar-dropdown :arrowless="screenUntil('tablet')">
    <b-icon v-if="screenFrom('desktop')" icon="bell"/>
    <b-icon v-else icon="bell" size="is-small"/>
    <template #menu>
      <div ref="menu" class="notification_content">
        <div>新規行事追加</div>
        <hr>
        <div>新規行事追加</div>
        <hr>
        <div>通知一覧</div>
      </div>
    </template>
  </navbar-dropdown>
</template>
<script>
import { mapGetters } from 'vuex';
import NavbarDropdown from './NavbarDropdown.vue';

export default {
  components: {
    NavbarDropdown,
  },
  computed: {
    ...mapGetters('screen', {
      screenUntil: 'until',
      screenFrom: 'from',
    }),
  },
  mounted() {
    // デフォルトの表示を消す
    this.$refs.menu.parentNode.classList.add('p-0');
    this.$refs.menu.parentNode.style.border = 'none';
  },
};
</script>
<style lang="scss" scoped>
.notification_content {
  position: absolute;
  right: 0;
  width: 70vw;
  max-width: 500px;
}
</style>
