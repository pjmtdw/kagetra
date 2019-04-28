<template>
  <a :class="classes" v-on="$listeners" @click="onClick">
    <slot/>
  </a>
</template>
<script>
export default {
  props: {
    type: {
      type: String,
      default: null,
      validator(v) {
        return ['primary', 'danger', 'info', 'link', 'success', 'light', 'dark', 'text'].includes(v);
      },
    },
    href: {
      type: String,
      default: null,
    },
    outlined: {
      type: Boolean,
      default: false,
    },
  },
  computed: {
    classes() {
      const classes = ['button'];
      if (this.type) classes.push(`is-${this.type}`);
      if (this.outlined) classes.push('is-outlined');
      return classes;
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
