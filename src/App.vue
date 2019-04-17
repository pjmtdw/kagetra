<template>
  <div id="app" class="is-flex flex-column">
    <Navbar/>
    <router-view class="flex-grow-1"/>
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
