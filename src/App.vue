<template>
  <div id="app">
    <Navbar ref="navbar"/>
    <router-view v-touch:swipe.left="() => $refs.navbar.openMenu()" v-touch:swipe.right="() => $refs.navbar.closeMenu()"/>
  </div>
</template>
<script>
import { Navbar } from './containers';

export default {
  components: {
    Navbar,
  },
};
</script>
<style lang="scss">
@import 'assets/scss/common';
#app {
  background-image: url('/img/fuda.jpg');
  min-height: 100vh;
}
</style>
