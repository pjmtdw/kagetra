<template>
  <div class="wrapper" :style="`bottom: ${bottom}rem;`">
    <circle-button id="fab-main" variant="success" class="shadow" @click="onClick">
      <v-icon :name="mainIcon"/>
    </circle-button>
    <b-popover v-if="pop" target="fab-main" :show="showPop" placement="left">
      <div v-html="pop"/>
    </b-popover>
    <b-tooltip v-if="tip" target="fab-main" :show="showPop" placement="left">
      <div class="small text-nowrap text-left" v-html="tip"/>
    </b-tooltip>
    <template  v-for="(button, i) in buttons">
      <!-- eslint-disable-next-line -->
      <transition name="slide" @after-enter="showPop = true" @before-leave="showPop = false">
        <div v-if="isActive" :key="button.icon" class="fab-sub position-absolute" :style="`bottom: ${3.2 + 2.5 * i + (i + 1) * 0.5}rem;`">
          <circle-button :id="`fab-${button.icon}`" variant="success" size="sm"
                          class="sub-floating-button shadow" @click="button.onClick() === false && (isActive = false)">
            <v-icon :name="button.icon"/>
          </circle-button>
          <b-popover :target="`fab-${button.icon}`" :show="showPop" placement="left">
            {{ button.text }}
          </b-popover>
        </div>
      </transition>
    </template>
  </div>
</template>
<script>
import { isString } from 'lodash';
import { env } from '@/utils';
import { CircleButton } from '@/components';

export default {
  components: {
    CircleButton,
  },
  props: {
    icon: {
      type: [String, Function],
      required: true,
    },
    pop: {
      type: String,
      default: null,
    },
    tip: {
      type: String,
      default: null,
    },
    buttons: {
      type: Array,
      default: null,
    },
    noHide: {
      type: Boolean,
      default: false,
    },
  },
  data() {
    return {
      isActive: false,
      showPop: false,
      btm: 1,
      rem: null,
    };
  },
  computed: {
    bottom: {
      get() {
        return this.noHide ? 1 : this.btm;
      },
      set(val) {
        this.btm = val;
      },
    },
    mainIcon() {
      if (isString(this.icon)) return this.icon;
      return this.icon(this.isActive);
    },
  },
  mounted() {
    this.rem = env.rem();
    window.addEventListener('scroll', this.onScroll);
  },
  destroyed() {
    window.removeEventListener('scroll', this.onScroll);
  },
  methods: {
    onClick() {
      if (this.buttons) this.isActive = !this.isActive;
      else this.$emit('click');
    },
    onScroll() {
      this.bottom = (this.rem - document.documentElement.scrollTop) / this.rem;
    },
  },
};
</script>
<style lang="scss" scoped>
.wrapper {
  position: fixed;
  right: 1rem;
  z-index: 1030;
}
.fab-sub {
  width: 3.2rem;
  text-align: center;
  z-index: -1;
}
.slide-enter, .slide-leave-to {
  bottom: 1rem !important;
  opacity: 0;
}
.slide-enter-active, .slide-leave-active {
  transition: all .3s;
}
</style>
