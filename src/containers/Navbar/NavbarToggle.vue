<template>
  <div>
    <a role="button" class="navbar-burger" :class="{ active: isActive }" aria-label="menu" aria-expanded="false" @click="isActive = !isActive">
      <span aria-hidden="true"></span>
      <span aria-hidden="true"></span>
      <span aria-hidden="true"></span>
    </a>
    <transition name="menu" @before-enter="preventBodyScroll" @after-leave="allowBodyScroll">
      <div v-show="isActive" class="navbar-toggle-menu" :style="`height: calc(100vh - ${navHeight}px);`">
        <slot/>
      </div>
    </transition>
    <transition name="backdrop">
      <div v-show="isActive" class="backdrop" :style="`height: calc(100vh - ${navHeight}px);`" @click.stop="isActive = false"/>
    </transition>
  </div>
</template>
<script>
export default {
  data() {
    return {
      isActive: false,
      navHeight: 0,
    };
  },
  mounted() {
    this.navHeight = this.$el.clientHeight;
    this.$router.afterEach(() => {
      this.isActive = false;
    });
  },
  methods: {
    allowBodyScroll() {
      document.documentElement.style.overflow = '';
      document.body.style.overflow = '';
    },
    preventBodyScroll() {
      document.documentElement.style.overflow = 'hidden';
      document.body.style.overflow = 'hidden';
    },
  },
};
</script>
<style lang="scss" scoped>
.navbar-burger {
  color: #4a4a4a;
  cursor: pointer;
  display: block;
  height: 3.25rem;
  position: relative;
  width: 3.25rem;
  margin-left: auto;
  &:hover {
    background-color: rgba(0, 0, 0, .05);
  }
  span {
    background-color: currentColor;
    display: block;
    height: 1px;
    left: calc(50% - 8px);
    position: absolute;
    transform-origin: center;
    transition-duration: 86ms;
    transition-property: background-color, opacity, transform;
    transition-timing-function: ease-out;
    width: 16px;
    &:nth-child(1) {
      top: calc(50% - 6px);
    }
    &:nth-child(2) {
      top: calc(50% - 1px);
    }
    &:nth-child(3) {
      top: calc(50% + 4px);
    }
  }
  &.active span {
    &:nth-child(1) {
      transform: translateY(5px) rotate(45deg);
    }
    &:nth-child(2) {
      opacity: 0;
    }
    &:nth-child(3) {
      transform: translateY(-5px) rotate(-45deg);
    }
  }
}
.navbar-toggle-menu {
  display: block;
  position: absolute;
  right: 0;
  z-index: 40;
  white-space: nowrap;
  overflow-y: scroll;
  background-color: white;
}
.menu-enter, .menu-leave-to {
  transform: translateX(100%);
}
.menu-enter-active, .menu-leave-active {
  transition: transform .3s;
}

.backdrop {
  position: absolute;
  width: 100%;
  z-index: 30;
  left: 0;
  background-color: rgba(0, 0, 0, .1);
}
.backdrop-enter, .backdrop-leave-to {
  opacity: 0;
}
.backdrop-enter-active, .backdrop-leave-active {
  transition: opacity .3s;
}
</style>
