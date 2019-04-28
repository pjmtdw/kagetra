<template>
  <div :class="classes">
    <label v-if="label" class="label">
      <span class="has-text-weight-normal is-size-6">{{ label }}</span>
      <slot/>
    </label>
    <slot v-else/>
    <p v-if="message" class="help">{{ getStringMessage(message) }}</p>
    <p v-if="error && errorMessage" class="help is-danger">{{ getStringMessage(errorMessage) }}</p>
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
        const types = ['primary', 'danger', 'info', 'success', 'warning'];
        if (_.isString(v)) {
          return types.includes(v);
        }
        return _.every(v, (val, key) => types.includes(key));
      },
    },
    hasError: {
      type: Boolean,
      default: false,
    },
    message: {
      type: [String, Array, Object],
      default: null,
    },
    errorMessage: {
      type: [String, Array, Object],
      default: null,
    },
    horizontal: {
      type: Boolean,
      default: false,
    },
  },
  data() {
    return {
      showValidation: false,
      valid: false,
    };
  },
  computed: {
    classes() {
      const classes = ['field'];
      if (this.horizontal) classes.push('is-horizontal');
      if (this.statusType) classes.push(`is-${this.statusType}`);
      return classes;
    },
    statusType() {
      if (this.error) return 'danger';
      if (this.showValidation) return 'success';
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
    error() {
      return this.hasError || (this.showValidation && !this.valid);
    },
  },
  methods: {
    onInput(e) {
      this.$emit('input', e.target.value);
    },
    getStringMessage(message) {
      if (_.isString(message)) return message;
      // ['a', 'b'] => 'a\nb'
      if (_.isArray(message)) return _.join(message, '\n');
      // { 'a': true, 'b': false, 'c': true } => 'a\nc'
      if (_.isObject(message)) {
        return _.reduce(message, (result, val, k) => (val ? `${result}\n${k}` : result), '');
      }
      return null;
    },
    // called from VForm or form items
    checkValidity() {
      this.showValidation = true;
    },
    hideValidation() {
      this.showValidation = false;
    },
    onValid() {
      this.valid = true;
    },
    onInvalid() {
      this.valid = false;
    },
  },
};
</script>
<style lang="scss" scoped>
.is-horizontal {
  .label {
    display: flex;
    align-items: center;
    span {
      white-space: nowrap;
      margin-right: .5rem;
    }
  }
}
</style>
