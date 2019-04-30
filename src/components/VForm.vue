<template>
  <b-form v-bind="attrs" v-on="$listeners" @submit.prevent>
    <slot/>
  </b-form>
</template>
<script>
export default {
  data() {
    return {
      validated: false,
    };
  },
  computed: {
    attrs() {
      const attrs = {
        novalidate: true,
        ...this.$attrs,
      };
      if (this.validated) attrs.validated = true;
      return attrs;
    },
  },
  methods: {
    validate() {
      if (this.checkValidity()) return true;
      this.validated = true;
      return false;
    },
    checkValidity() {
      return this.$el.checkValidity();
    },
    reset() {
      this.validated = false;
    },
  },
};
</script>
