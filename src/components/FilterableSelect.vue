<template>
  <div class="filterable-select">
    <div class="query-input position-relative">
      <slot :on-input="onInput" :on-focus="() => isActive = true" :on-blur="() => isActive = false">
        <v-input :value="value" @input="onInput" @focus="isActive = true" @blur="isActive = false"/>
      </slot>
      <div class="after-query-input">
        <v-icon name="angle-down"/>
      </div>
    </div>
    <div class="dropdown-menu w-100" :class="{ show: isActive }">
      <template v-if="data && data.length">
        <!-- eslint-disable-next-line vue/require-v-for-key -->
        <a v-for="item in data" class="dropdown-item px-3" href="#" tabindex="-1" @mousedown="onSelect(item)" @touchstart="onSelect(item)">
          <slot name="item" :item="item">
            {{ item }}
          </slot>
        </a>
      </template>
      <span v-else class="dropdown-item-text">
        <slot v-if="data === null" name="empty">キーワードを入力してください</slot>
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
      default: null,
    },
    value: {
      type: [String, Number, Object],
      default: null,
    },
  },
  data() {
    return {
      isActive: false,
    };
  },
  methods: {
    onInput() {
      if (!this.isActive && document.activeElement !== document.body) this.isActive = true;
      this.$emit('input', null);
    },
    onSelect(item) {
      this.$emit('input', item);
    },
  },
};
</script>
<style lang="scss" scoped>
.filterable-select {
  position: relative;
}
.after-query-input {
  display: flex;
  align-items: center;
  height: 100%;
  position: absolute;
  top: 0;
  right: .75rem;
  pointer-events: none;
}
.dropdown-menu {
  max-height: 40vh;
  overflow-y: auto;
}
</style>
<style lang="scss">
.query-input input {
  cursor: pointer;
}
</style>
