<template>
  <input v-if="this.statusType" class="input" :class="`is-${statusType}`"
         :type="type" :placeholder="placeholder" :value="value" :readonly="readonly" v-on="listeners">
  <input v-else class="input" :type="type" :placeholder="placeholder" :value="value" :readonly="readonly" v-on="listeners">
</template>
<script>
export default {
  props: {
    value: {
      type: String,
      default: '',
    },
    type: {
      type: String,
      default: 'text',
    },
    placeholder: {
      type: String,
      default: null,
    },
    readonly: {
      type: Boolean,
      default: false,
    },
    autofocus: {
      type: Boolean,
      default: false,
    },
  },
  computed: {
    listeners() {
      return {
        ...this.$listeners,
        input: e => this.$emit('input', e.target.value),
      };
    },
    // Find parent Field, max 3 levels deep.
    parentField() {
      let parent = this.$parent;
      for (let i = 0; i < 3; i++) {
        if (parent && !parent.name === 'VField') {
          parent = parent.$parent;
        }
      }
      return parent;
    },
    statusType() {
      if (!this.parentField) return null;
      if (!this.parentField.type) return null;
      return this.parentField.statusType;
    },
  },
  mounted() {
    if (this.autofocus) {
      this.$el.focus();
    }
  },
};
</script>
<style lang="scss" scoped>

</style>
