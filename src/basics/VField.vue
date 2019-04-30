<template>
  <div class="form-group" :class="{ horizontal }">
    <label v-if="label" :for="labelFor">{{ label }}</label>
    <slot/>
    <small v-if="help" class="form-text text-muted">{{ help }}</small>
    <div v-if="validFeedback" class="valid-feedback">{{ validFeedback }}</div>
    <div v-if="invalidFeedback" class="invalid-feedback">{{ invalidFeedback }}</div>
  </div>
</template>
<script>
import { noop } from 'lodash';
import { waitUntil } from '@/utils';

export default {
  props: {
    label: {
      type: String,
      default: null,
    },
    help: {
      type: String,
      default: null,
    },
    feedback: {
      type: [String, Object], // if type is String, interpreted as invalid feedback
      default: null,
    },
    horizontal: {
      type: Boolean,
      default: false,
    },
  },
  data() {
    return {
      labelFor: null,
    };
  },
  computed: {
    validFeedback() {
      if (this.feedback && this.feedback.valid) return this.feedback.valid;
      return null;
    },
    invalidFeedback() {
      if (this.feedback) {
        if (this.feedback.invalid) return this.feedback.invalid;
        if (!this.feedback.valid) return this.feedback;
      }
      return null;
    },
  },
  mounted() {
    if (this.$slots.default.length === 1) {
      const inputTags = ['input', 'select', 'textarea'];
      const slotElm = this.$slots.default[0].elm;
      if (inputTags.includes(slotElm.tagName.toLowerCase())) {
        waitUntil(() => slotElm.id, 500).then(() => {
          this.labelFor = slotElm.id;
        }).catch(noop);
      }
    }
  },
};
</script>
<style lang="scss" scoped>
.horizontal {
  label {
    display: inline-block;
    margin-right: .25rem;
  }
  input, select {
    display: inline-block;
    width: auto;
  }
}
</style>
