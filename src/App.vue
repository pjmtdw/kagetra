<template>
  <div id="app">
    <Navbar/>
    <router-view/>
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
