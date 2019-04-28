<template>
  <div class="field has-addons">
    <div v-if="$slots.prepend" class="control">
      <slot name="prepend"/>
    </div>
    <div class="control" :class="{ 'is-expanded': expanded === 'default' }">
      <slot/>
    </div>
    <div v-if="$slots.append" class="control">
      <slot name="append"/>
    </div>
  </div>
</template>
<script>
export default {
  props: {
    expanded: {
      type: String,
      default: 'default',
      validator(v) {
        return ['default', 'prepend', 'append'].includes(v);
      },
    },
  },
};
</script>
