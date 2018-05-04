<template>
  <nav v-once id="topbar" class="navbar navbar-expand-md navbar-light bg-light" :class="{public: isPublic}">
    <button class="navbar-toggler ml-auto" type="button" data-toggle="collapse" data-target="#navbarContent" aria-controls="navbarContent" aria-expanded="false" aria-label="Toggle navigation">
      <span class="navbar-toggler-icon"/>
    </button>
    <div v-if="!isPublic" id="navbarContent" class="collapse navbar-collapse">
      <ul class="navbar-nav mr-auto">
        <li v-for="e in list" :key="e.alias" class="nav-item mx-2">
          <a class="nav-link" :class="{active: routeName === e.alias}" :href="`/${e.alias}`">{{ e.name }}</a>
        </li>
      </ul>
    </div>
    <div v-else id="navbarContent" class="collapse navbar-collapse">
      <ul class="navbar-nav mr-auto">
        <li v-for="e in publicList" :key="e.alias" class="nav-item mx-2">
          <a class="nav-link" :class="{active: routeName === e.alias}" :href="`/public/${e.alias}`">{{ e.name }}</a>
        </li>
      </ul>
    </div>
  </nav>
</template>
<script>
export default {
  data() {
    return {
      list: [
        { alias: 'top', name: 'TOP' },
        { alias: 'bbs', name: '掲示板' },
        { alias: 'result', name: '大会結果' },
        { alias: 'schedule', name: '予定表' },
        { alias: 'wiki', name: 'Wiki' },
        { alias: 'album', name: 'アルバム' },
        { alias: 'addrbook', name: '名簿' },
      ],
      publicList: [
        { alias: 'top', name: 'TOP' },
        { alias: 'bbs', name: '掲示板' },
        { alias: 'schedule', name: '予定表' },
        { alias: 'wiki', name: 'Wiki' },
      ],
    };
  },
};
</script>
<style lang="scss">
// 全体に適用するスタイル
@import '../sass/common.scss';
nav#topbar {
  .public {
    $public_top_bar_color: green;
    // background: $public_top_bar_color !important;
    // #navbarContent li a {background: $public_top_bar_color !important;}
    // #navbarContent {background: $public_top_bar_color !important;}
    // #navbarContent ul {background: $public_top_bar_color !important;}
  }
}
</style>

