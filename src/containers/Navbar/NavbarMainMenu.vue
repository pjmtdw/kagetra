<template>
  <component :is="screenFrom('lg') ? 'b-navbar-nav' : 'div'">
    <template v-for="page in pages">
      <template v-if="page.hasPublicPage || hasAuthority(page.require)">
        <b-nav-item v-if="page.path" :key="page.path" :to="`/${page.path}`" active-class="active">
          {{ page.title }}
        </b-nav-item>
        <b-nav-item-dropdown v-else-if="screenFrom('lg')" :key="page.path" :text="page.title">
          <template v-for="p in page.children">
            <b-dropdown-item v-if="hasAuthority(page.require)" :key="p.path" :to="p.path" active-class="active">
              {{ p.title }}
            </b-dropdown-item>
          </template>
        </b-nav-item-dropdown>
        <navbar-collapse v-else :key="page.path">
          <template #trigger>
            <span>{{ page.title }}</span>
          </template>
          <template v-for="p in page.children">
            <b-nav-item v-if="hasAuthority(page.require)" :key="p.path" :to="p.path" active-class="active">
              {{ p.title }}
            </b-nav-item>
          </template>
        </navbar-collapse>
      </template>
    </template>
  </component>
</template>
<script>
import { mapGetters } from 'vuex';
import NavbarCollapse from './NavbarCollapse.vue';

export default {
  components: {
    NavbarCollapse,
  },
  props: {
    pages: {
      type: Array,
      required: true,
    },
  },
  computed: {
    ...mapGetters('auth', ['hasAuthority']),
  },
};
</script>
