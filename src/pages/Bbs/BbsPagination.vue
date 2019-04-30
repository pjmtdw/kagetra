<template>
  <ul class="pagination justify-content-center">
    <li v-for="p in pages" :key="p.text" class="page-item" :class="{ active: page === p.text }">
      <router-link class="page-link" :to="p.link">
        {{ p.text }}
      </router-link>
    </li>
  </ul>
</template>
<script>
export default {
  props: {
    page: {
      type: [Number, String],
      required: true,
    },
    pages: {
      type: Array,
      required: true,
    },
  },
};
</script>
