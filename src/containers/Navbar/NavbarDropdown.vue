<template>
  <div v-if="type === 'overlay'" class="navbar-item has-dropdown" :class="{ 'is-active': isActive }">
    <a ref="trigger" class="navbar-link" :class="{ 'is-arrowless': arrowless }" @click.capture="isActive = !isActive">
      <slot/>
    </a>
    <div class="navbar-dropdown" :class="position ? `is-${position}` : ''" @click.stop>
      <slot name="menu"/>
    </div>
  </div>
  <div v-else class="navbar-item p-0">
    <a class="navbar-link is-arrowless is-flex align-items-center w-100" @click.stop="isActive = !isActive">
      <slot/>
      <span class="ml-2"/>
      <b-icon class="arrow" :class="{ active: isActive }" icon="angle-down"/>
    </a>
    <div ref="menu" class="navbar-dropdown_menu pl-3">
      <div ref="wrapper">
        <slot name="menu"/>
      </div>
    </div>
  </div>
</template>
<script>
export default {
  props: {
    type: {
      type: String,
      default: 'overlay', // or collapse
    },
    position: {
      type: String,
      default: null,
    },
    arrowless: {
      type: Boolean,
      default: false,
    },
  },
  data() {
    return {
      isActive: false,
    };
  },
  watch: {
    isActive(newVal) {
      if (this.type === 'overlay') return;
      if (newVal) {
        this.$refs.menu.style.height = '0';
        this.$nextTick(() => {
          this.$refs.menu.style.height = `${this.$refs.wrapper.clientHeight}px`;
          setTimeout(() => this.$refs.menu.scrollIntoView({ behavior: 'smooth', block: 'nearest', inline: 'nearest' }), 200);
        });
      } else {
        this.$refs.menu.style.height = '0';
      }
    },
  },
  mounted() {
    if (this.type === 'overlay') {
      document.addEventListener('click', this.hideDropdown);
      this.$router.afterEach(this.hideDropdown);
    }
  },
  beforeDestroy() {
    if (this.type === 'overlay') {
      document.removeEventListener('click', this.hideDropdown);
    }
  },
  methods: {
    hideDropdown(e) {
      let node = e.target;
      if (e.target === undefined) node = null;
      for (let i = 0; i < 5; i++) {
        if (node === null) break;
        if (node === this.$refs.trigger) return;
        node = node.parentNode;
      }
      this.isActive = false;
    },
  },
};
</script>
<style lang="scss" scoped>
@import '../../assets/scss/bulma_mixins';

@include touch() {
  .has-dropdown {
    .navbar-link {
      display: flex;
      align-items: center;
      height: 100%;
      padding: 0 1.5rem;
    }
    .navbar-dropdown {
      display: none;
      position: absolute;
      top: 100%;
      right: 0;
      min-width: 60vh;
      max-width: 90vh;
    }
    &.is-active {
      .navbar-dropdown {
        display: block;
      }
    }
  }
}

.navbar-dropdown_menu {
  height: 0;
  overflow: hidden;
  transition: height .2s;
}

.arrow {
  transition: transform .2s;
  &.active {
    transform: rotate(180deg);
  }
}
</style>
