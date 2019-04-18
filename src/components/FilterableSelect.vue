<template>
  <div class="dropdown w-100" :class="{ 'is-active': isActive }">
    <div class="select is-fullwidth" :class="{ 'is-loading': loading }">
      <v-input ref="input" v-model="input" class="query-input" :placeholder="placeholder" @focus="isActive = true" @blur="onBlur"/>
    </div>
    <div class="dropdown-menu w-100">
      <div class="dropdown-content has-text-weight-normal is-size-7">
        <template v-if="input && input.length && data.length">
          <!-- eslint-disable-next-line vue/require-v-for-key -->
          <a v-for="item in data" href="#" class="dropdown-item" tabindex="-1" @click.prevent="onSelect(item)">
            <slot :item="item">
              {{ item }}
            </slot>
          </a>
        </template>
        <div v-else class="dropdown-item">
          <slot v-if="loading"/>
          <slot v-else-if="input === null || input.length === 0" name="empty"/>
          <slot v-else-if="data.length === 0" name="none"/>
        </div>
      </div>
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
      setTimeout(() => {
        this.isActive = false;
      }, 100);
    },
    onSelect(item) {
      this.$emit('input', item);
    },
  },
};
</script>
<style lang="scss" scoped>
.query-input {
  cursor: pointer;
}

.dropdown-content {
  max-height: 40vh;
  overflow-y: auto;
}
</style>
