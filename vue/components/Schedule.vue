<template>
  <main class="hello">{{ message }}</main>
</template>
<script>
export default {
  data() {
    return {
      message: '予定表',
    };
  },
};
</script>
<style lang="scss" scoped>
.hello {
  color: red;
}
</style>
