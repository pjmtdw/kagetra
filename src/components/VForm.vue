<template>
  <form novalidate @submit.prevent>
    <slot/>
  </form>
</template>
<script>
export default {
  computed: {
    fields() {
      return this.$slots.default
        .filter(e => e.componentOptions && e.componentOptions.tag === 'v-field')
        .map(e => e.componentInstance);
    },
  },
  methods: {
    checkValidity() {
      let result = true;
      this.fields.forEach((e) => {
        if (!e.valid) {
          result = false;
          return false;
        }
        return true;
      });
      if (!result) {
        this.fields.forEach((e) => {
          e.checkValidity();
        });
      }
      return result;
    },
    reset() {
      this.fields.forEach((e) => {
        e.hideValidation();
      });
    },
  },
};
</script>
