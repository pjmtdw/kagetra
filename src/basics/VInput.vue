<template>
  <b-form-input ref="input" v-bind="$attrs" v-on="$listeners"/>
</template>
<script>
export default {
  props: {
    autofocus: {
      type: Boolean,
      default: false,
    },
  },
  mounted() {
    ['focus', 'blur', 'select'].forEach((method) => {
      this[method] = this.$refs.input[method];
    });
    if (this.autofocus) {
      this.focus();
    }
  },
};
</script>
