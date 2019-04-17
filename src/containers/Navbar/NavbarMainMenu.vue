<template>
  <div>
    <template v-for="page in pages">
      <template v-if="page.hasPublicPage || hasAuthority(page.require)">
        <router-link v-if="page.dir" :key="page.dir" :to="`/${page.dir}`" class="navbar-item" active-class="is-active">
          {{ page.title }}
        </router-link>
        <navbar-dropdown v-else :type="screenFrom('desktop') ? 'overlay' : 'collapse'">
          <span>{{ page.title }}</span>
          <template #menu>
            <template v-for="p in page.children">
              <router-link v-if="hasAuthority(page.require)" :key="p.dir" :to="p.dir" class="navbar-item" active-class="is-active">
                {{ p.title }}
              </router-link>
            </template>
          </template>
        </navbar-dropdown>
      </template>
    </template>
  </div>
</template>
<script>
import { mapGetters } from 'vuex';
import NavbarDropdown from './NavbarDropdown.vue';

export default {
  components: {
    NavbarDropdown,
  },
  props: {
    pages: {
      type: Array,
      required: true,
    },
  },
  computed: {
    ...mapGetters('auth', ['hasAuthority']),
    ...mapGetters('screen', {
      screenUntil: 'until',
      screenFrom: 'from',
    }),
  },
};
</script>
