<template>
  <div>
    <b-dropdown-item>新規行事追加</b-dropdown-item>
    <b-dropdown-divider/>
    <b-dropdown-item>新規行事追加</b-dropdown-item>
    <b-dropdown-divider/>
    <b-dropdown-item>通知一覧</b-dropdown-item>
  </div>
</template>
<script>
import { mapGetters } from 'vuex';

export default {
  computed: {
    ...mapGetters('screen', {
      screenUntil: 'until',
      screenFrom: 'from',
    }),
  },
};
</script>
<style lang="scss" scoped>
</style>
