<template>
  <a class="button" :class="`is-${type}`" v-on="$listeners" @click="onClick">
    <slot/>
  </a>
</template>
<script>
export default {
  props: {
    type: {
      type: String,
      default: 'primary',
      validator(v) {
        return ['primary', 'danger', 'info', 'link', 'success'].includes(v);
      },
    },
    href: {
      type: String,
      default: null,
    },
  },
  methods: {
    onClick() {
      if (this.href) {
        this.$router.push(this.href);
      }
    },
  },
};
</script>
