<template>
  <main class="hello">{{ message }}</main>
</template>
<script>
export default {
  data() {
    return {
      message: 'アルバム',
    };
  },
};
</script>
<style lang="scss" scoped>
.hello {
  color: red;
}
</style>
