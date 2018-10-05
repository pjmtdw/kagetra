<template>
  <span :class="`${type}-icon`" :title="title" :data-placement="placement"/>
</template>
<script>
export default {
  props: {
    type: {
      type: String,
      default: 'help',
    },
    title: {
      type: String,
      required: true,
    },
    placement: {
      type: String,
      default: 'top',
    },
  },
  // watch: {
  //   title() {
  //     $(this.$el).tooltip();
  //   },
  // },
  mounted() {
    $(this.$el).tooltip();
  },
};
</script>
<style>

</style>
