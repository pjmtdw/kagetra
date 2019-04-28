<template>
  <div class="collapse">
    <div class="collapse-trigger" @click="toggle">
      <slot name="trigger" :open="isOpen"/>
    </div>
    <transition :name="animation" @after-enter="onEntered">
      <div v-show="isOpen" ref="content" class="collapse-content" :style="`height: ${contentHeight};`" :aria-expanded="isOpen">
        <slot/>
      </div>
    </transition>
  </div>
</template>
<script>
import { calcElementHeight } from '@/utils';

export default {
  props: {
    open: {
      type: Boolean,
      default: true,
    },
    animation: {
      type: String,
      default: 'fade',
    },
  },
  data() {
    return {
      isOpen: this.open,
      contentHeight: '0',
    };
  },
  watch: {
    open() {
      this.toggle();
    },
  },
  methods: {
    toggle() {
      this.isOpen = !this.isOpen;
      this.$emit('update:open', this.isOpen);
      this.$emit(this.isOpen ? 'open' : 'close');
      this.$nextTick(() => {
        if (this.isOpen) {
          this.contentHeight = calcElementHeight(this.$refs.content).height;
        } else {
          setTimeout(() => {
            this.contentHeight = '0px';
          }, 10);
        }
      });
      if (this.isOpen) {
        this.contentHeight = '0';
      } else {
        this.contentHeight = calcElementHeight(this.$refs.content).height;
      }
    },
    onEntered() {
      this.$nextTick(() => {
        this.contentHeight = 'auto';
      });
      this.$emit('shown');
    },
  },
};
</script>
<style lang="scss" scoped>
.collapse-content {
  backface-visibility: hidden;  // chromeで起きることがあるtransition後のちらつき対策
}
.slide-enter-active, .slide-leave-active {
  overflow-y: hidden;
  transition: height .3s;
}
</style>
