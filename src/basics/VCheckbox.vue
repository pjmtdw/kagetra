<template>
  <b-checkbox v-bind="attrs" v-on="listeners">
    <slot/>
  </b-checkbox>
</template>
<script>
import { FormItemMixin } from '@/utils';

export default {
  mixins: [
    FormItemMixin,
  ],
  computed: {
    attrs() {
      return {
        ...this.$attrs,
        type: `is-${this.$attrs.type || 'info'}`,
      };
    },
    listeners() {
      return {
        ...this.$listeners,
        input: this.onInput,
      };
    },
  },
  mounted() {
    this.inputElement = this.$el.querySelector('input[type="checkbox"]');
  },
  methods: {
    onInput(e) {
      this.updateValidity(e.target);
    },
  },
};
</script>
<style lang="scss">
.b-checkbox {
  .check {
    border-width: 1px!important;
    box-shadow: inset;
  }
  input[type=checkbox]:not(:checked) + .check {
    opacity: .6!important;
    box-shadow: .3px .4px 1px rgba(0, 0, 0, .3) inset;
  }
}
</style>
