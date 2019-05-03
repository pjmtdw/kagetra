<template>
  <ul class="pagination mb-0">
    <!-- eslint-disable vue/require-v-for-key -->
    <template v-for="item in links" class="page-item">
      <li v-if="item.tooltip" v-b-tooltip="item.tooltip" class="page-item" :class="{ active: item.active }" @click="item.onClick && item.onClick()">
        <router-link v-if="item.to" class="page-link" :to="item.to">{{ item.text }}</router-link>
        <span v-else class="page-link">{{ item.text }}</span>
      </li>
      <li v-else class="page-item" :class="{ active: item.active }" @click="item.onClick && item.onClick()">
        <router-link v-if="item.to" class="page-link" :to="item.to">{{ item.text }}</router-link>
        <span v-else class="page-link">{{ item.text }}</span>
      </li>
    </template>
  </ul>
</template>
<script>
export default {
  props: {
    links: {
      type: Array,
      default: null,
    },
  },
};
</script>
