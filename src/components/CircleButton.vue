<template>
  <b-button :variant="variant" class="circle-button rounded-circle" :class="`circle-button-${size}`" v-on="$listeners">
    <slot/>
  </b-button>
</template>
<script>
export default {
  props: {
    variant: {
      type: String,
      dedfault: 'primary',
    },
    size: {
      type: String,
      default: 'md',
    },
  },
};
</script>

<style lang="scss" scoped>
.circle-button {
  display: inline-flex;
  justify-content: center;
  align-items: center;
  width: 3.2rem;
  height: 3.2rem;
  &-sm {
    width: 2.4rem;
    height: 2.4rem;
  }
}
</style>
