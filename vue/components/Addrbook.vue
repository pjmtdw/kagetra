<template>
  <main class="hello">{{ message }}</main>
</template>
<script>
export default {
  data() {
    return {
      message: '名簿',
    };
  },
};
</script>
<style lang="scss" scoped>
.hello {
  color: red;
}
</style>
