<template>
  <textarea
    :class="classes"
    :placeholder="placeholder"
    :value="value"
    :readonly="readonly"
    :style="textareaStyle"
    v-on="listeners"
  />
</template>
<script>
import { FormItemMixin, calcTextareaHeight } from '@/utils';

export default {
  mixins: [
    FormItemMixin,
  ],
  props: {
    value: {
      type: String,
      default: '',
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
    autosize: {
      type: [Boolean, Object],
      default: false,
    },
    rows: {
      type: Number,
      default: 3,
    },
  },
  data() {
    return {
      textareaStyle: {},
    };
  },
  computed: {
    listeners() {
      return {
        ...this.$listeners,
        input: this.onInput,
      };
    },
    classes() {
      const classes = ['textarea'];
      if (this.statusType) classes.push(`is-${this.statusType}`);
      return classes;
    },
  },
  watch: {
    value() {
      if (this.autosize) {
        this.$nextTick(this.resizeTextarea);
      }
    },
  },
  mounted() {
    if (this.autofocus) {
      this.$el.focus();
    }
    if (this.autosize) {
      this.resizeTextarea();
    }
  },
  methods: {
    onInput(e) {
      this.updateValidity();
      this.$emit('input', e.target.value);
    },
    resizeTextarea() {
      const { minRows, maxRows } = this.autosize;
      this.textareaStyle = calcTextareaHeight(this.$el, minRows || 0, maxRows || null);
    },
  },
};
</script>
<style lang="scss" scoped>

</style>
