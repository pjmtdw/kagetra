<template>
  <div class="filterable-select">
    <div class="position-relative">
      <v-input ref="input" v-model="input" class="query-input" :class="{ loading }" :placeholder="placeholder" @focus="isActive = true" @blur="onBlur"/>
      <div class="after-query-input" @click="$refs.input.focus()">
        <b-spinner v-if="loading" type="grow"/>
        <v-icon v-else name="angle-down"/>
      </div>
    </div>
    <div class="dropdown-menu w-100" :class="{ show: isActive }">
      <template v-if="input && input.length && data.length">
        <!-- eslint-disable-next-line vue/require-v-for-key -->
        <a v-for="item in data" class="dropdown-item px-3" href="#" tabindex="-1" @mousedown="onSelect(item)" @touchstart="onSelect(item)">
          <slot :item="item">
            {{ item }}
          </slot>
        </a>
      </template>
      <span v-else class="dropdown-item-text">
        <slot v-if="loading" name="loading">読込中...</slot>
        <slot v-else-if="input === null || input.length === 0" name="empty">キーワードを入力してください</slot>
        <slot v-else-if="data.length === 0" name="none">候補が見つかりません</slot>
      </span>
    </div>
  </div>
</template>
<script>
import { VInput } from '../basics';

export default {
  components: {
    VInput,
  },
  props: {
    data: {
      type: Array,
      required: true,
    },
    placeholder: {
      type: String,
      default: null,
    },
    value: {
      type: [String, Number, Object],
      default: null,
    },
    loading: {
      type: Boolean,
      default: false,
    },
    // selectしたときにinputにitemのプロパティをセットするため
    field: {
      type: String,
      default: null,
    },
    fetchMethod: {
      type: Function,
      default: null,
    },
  },
  data() {
    return {
      input: null,
      isActive: false,
    };
  },
  watch: {
    value(v) {
      if (this.field) this.input = v[this.field];
      else this.input = v;
    },
    input() {
      if (!this.isActive && document.activeElement === this.$refs.input.$el) this.isActive = true;
      if (this.fetchMethod) this.fetchMethod(this.input);
    },
  },
  methods: {
    onBlur() {
      this.isActive = false;
    },
    onSelect(item) {
      this.$emit('input', item);
      this.isActive = false;
    },
  },
};
</script>
<style lang="scss" scoped>
.filterable-select {
  position: relative;
}
.query-input {
  padding-right: calc(1.5em + .75rem);
  cursor: pointer;
}
.after-query-input {
  display: flex;
  align-items: center;
  height: 100%;
  position: absolute;
  top: 0;
  right: .75rem;
  cursor: pointer;
}
.dropdown-menu {
  max-height: 40vh;
  overflow-y: auto;
}
</style>
