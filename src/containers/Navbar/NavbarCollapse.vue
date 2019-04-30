<template>
  <b-nav-item class="navbar-collapse">
    <div class="d-flex" href="#" @click.stop.prevent="isActive = !isActive">
      <slot name="trigger"/>
      <v-icon class="arrow ml-auto" :class="{ active: isActive }" name="angle-down"/>
    </div>
    <div ref="content" class="navbar-collapse-content" :style="{ height: contentHeight }">
      <div ref="wrapper">
        <slot/>
      </div>
    </div>
  </b-nav-item>
</template>
<script>
export default {
  data() {
    return {
      isActive: false,
      contentHeight: '0',
    };
  },
  watch: {
    isActive(newVal) {
      if (newVal) {
        this.contentHeight = '0';
        this.$nextTick(() => {
          this.contentHeight = `${this.$refs.wrapper.clientHeight}px`;
          setTimeout(() => {
            this.$refs.content.scrollIntoView({ behavior: 'smooth', block: 'nearest', inline: 'nearest' });
          }, 200);
        });
      } else {
        this.contentHeight = '0';
      }
    },
  },
};
</script>
<style lang="scss" scoped>
.navbar-collapse-content {
  overflow: hidden;
  transition: height .2s ease-in-out;
  background-color: transparent;
}

.arrow {
  transition: transform .2s;
  &.active {
    transform: rotate(180deg);
  }
}
</style>
<style lang="scss">
.navbar-collapse {
  .nav-link {
    width: 100%;
  }
}
</style>
