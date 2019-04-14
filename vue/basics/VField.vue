<template>
  <div class="field">
    <label v-if="label" class="label">
      <span class="has-text-weight-normal is-size-7">{{ label }}</span>
      <div class="control">
        <slot/>
      </div>
    </label>
    <div v-else class="control">
      <slot/>
    </div>
    <p v-if="statusType" class="help" :class="`is-${statusType}`">{{ displayMessage }}</p>
  </div>
</template>
<script>
import _ from 'lodash';

export default {
  props: {
    label: {
      type: String,
      default: null,
    },
    type: {
      type: [String, Object],
      default: null,
      validator(v) {
        const types = ['primary', 'danger', 'info', 'link', 'success'];
        if (_.isString(v)) {
          return types.includes(v);
        }
        return _.every(v, (val, key) => types.includes(key));
      },
    },
    message: {
      type: [String, Array, Object],
      default: null,
    },
  },
  computed: {
    statusType() {
      if (_.isString(this.type)) return this.type;
      let ret = null;
      /* eslint-disable-next-line consistent-return */
      _.each(this.type, (v, k) => {
        if (v) {
          ret = k;
          return false;
        }
      });
      return ret;
    },
    displayMessage() {
      if (_.isString(this.message)) return this.message;
      // ['a', 'b'] => 'a\nb'
      if (_.isArray(this.message)) return _.join(this.message, '\n');
      // { 'a': true, 'b': false, 'c': true } => 'a\nc'
      if (_.isObject(this.message)) {
        return _.reduce(this.message, (result, val, k) => (val ? `${result}\n${k}` : result), '');
      }
      return null;
    },
  },
  methods: {
    onInput(e) {
      this.$emit('input', e.target.value);
    },
  },
};
</script>
<style lang="scss" scoped>

</style>
