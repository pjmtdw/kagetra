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
    rows: {
      type: [Number, String],
      default: 3,
    },
    maxRows: {
      type: [Number, String],
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
      const minRows = this.autosize.minRows || this.rows;
      const maxRows = this.autosize.maxRows || this.maxRows || null;
      this.textareaStyle = calcTextareaHeight(this.$el, minRows, maxRows);
    },
  },
};
</script>
