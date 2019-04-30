<template>
  <b-form-textarea ref="input" v-bind="attrs" :style="textareaStyle" v-on="listeners" @input.native="autosize && resizeTextarea()"/>
</template>
<script>
import { calcTextareaHeight } from '@/utils';

export default {
  props: {
    autofocus: {
      type: Boolean,
      default: false,
    },
    autosize: {
      type: [Boolean, Object],
      default: true,
    },
    // disable auto height function of b-form-textarea
    maxRows: {
      type: Number,
      default: 0,
    },
  },
  data() {
    return {
      textareaStyle: {},
    };
  },
  computed: {
    attrs() {
      return {
        rows: 3,
        noResize: true,
        ...this.$attrs,
      };
    },
    listeners() {
      return {
        ...this.$listeners,
        keydown(e) {
          e.stopPropagation();
        },
      };
    },
  },
  mounted() {
    ['focus', 'blur', 'select'].forEach((method) => {
      this[method] = this.$refs.input[method];
    });
    if (this.autofocus) {
      this.focus();
    }
    if (this.autosize) {
      this.resizeTextarea();
    }
  },
  methods: {
    resizeTextarea() {
      const { minRows, maxRows } = this.autosize;
      this.textareaStyle = calcTextareaHeight(this.$el, minRows || 0, maxRows || null);
    },
  },
};
</script>
