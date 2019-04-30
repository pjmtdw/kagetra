<template>
  <div class="wrapper mt-3">
    <transition name="slide" appear @after-leave="onClosed">
      <b-alert v-if="opened" class="message shadow-sm mx-auto" :class="{ 'alert-dismissible': dismissible }" :variant="variant" show>
        <h4 v-if="title" class="alert-heading">{{ title }}</h4>
        <span>{{ message }}</span>
        <b-button-close v-if="dismissible" class="close" @click="close"/>
      </b-alert>
    </transition>
  </div>
</template>
<script>
export default {
  data() {
    return {
      opened: false,
      container: null,
      title: null,
      message: null,
      variant: null,
      dismissible: null,
    };
  },
  created() {
    document.body.appendChild(this.$mount().$el);
  },
  destroyed() {
    document.body.removeChild(this.$el);
  },
  methods: {
    open(rawOptions) {
      const defaultOptions = {
        duration: 5000,
        dismissible: false,
      };
      const options = {
        ...defaultOptions,
        ...rawOptions,
      };
      this.title = options.title;
      this.message = options.message;
      this.variant = options.variant;
      this.dismissible = options.dismissible;
      setTimeout(this.close, options.duration);
      this.opened = true;
    },
    close() {
      this.opened = false;
    },
    onClosed() {
      this.$destroy();
    },
  },
};
</script>
<style lang="scss" scoped>
.wrapper {
  display: flex;
  width: 100%;
  position: fixed;
  top: 0;
  z-index: 1500;
  pointer-events: none;
}
.message {
  width: 380px;
  max-width: 95%;
  opacity: .95;
}
.close {
  pointer-events: auto;
}

.slide-enter, .slide-leave-to {
  opacity: 0;
  transform: translateY(-100%);
}
.slide-enter-active, .slide-leave-active {
  transition: all .5s;
}
</style>
