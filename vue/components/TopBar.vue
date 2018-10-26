<template>
  <nav v-once id="topbar" class="navbar navbar-expand-md navbar-light bg-light" :class="{public: gIsPublic}">
    <button class="navbar-toggler ml-auto" type="button" data-toggle="collapse" data-target="#navbarContent" aria-controls="navbarContent" aria-expanded="false" aria-label="Toggle navigation">
      <span class="navbar-toggler-icon"/>
    </button>
    <div v-if="!gIsPublic" id="navbarContent" class="collapse navbar-collapse">
      <ul class="navbar-nav mr-auto">
        <li v-for="x in list" :key="x.alias" class="nav-item mx-2" :class="{ active: x.alias === gRouteName }">
          <a class="nav-link" :href="`/${x.alias}`">{{ x.name }}</a>
          <!-- <a v-else class="nav-link active" :href="`/${x.alias}`" @click="toRouteTop">{{ x.name }}</a> -->
          <!-- <router-link v-else class="nav-link active" to="/">{{ x.name }}</router-link> -->
        </li>
        <li class="nav-item dropdown mx-2">
          <a class="nav-link dropdown-toggle" href="#" data-toggle="dropdown" @click.prevent>
            その他
          </a>
          <div class="dropdown-menu">
            <a v-if="admin" class="dropdown-item" href="/admin">管理画面</a>
            <!-- <a v-if="sub_admin" class="dropdown-item" href="/ut_karuta_list_form">公式フォーム受け取り</a> -->
            <a class="dropdown-item" href="/user_conf">ユーザ設定</a>
            <a class="dropdown-item" href="/login_log">ログイン履歴</a>
            <a class="dropdown-item" href="http://kagetora.bushidoo.com/top">通常版へ</a>
            <a class="dropdown-item" href="/user/logout">ログアウト</a>
          </div>
        </li>
      </ul>
    </div>
    <div v-else id="navbarContent" class="collapse navbar-collapse">
      <ul class="navbar-nav mr-auto">
        <li v-for="x in publicList" :key="x.alias" class="nav-item mx-2" :class="{ active: x.alias === gRouteName }">
          <a class="nav-link" :href="`/public/${x.alias}`">{{ x.name }}</a>
          <!-- <router-link v-else class="nav-link active" to="/">{{ x.name }}</router-link> -->
        </li>
      </ul>
      <a href="/" class="nav-link mx-2">ログイン</a>
      <a href="http://kagetora.bushidoo.com" class="nav-link mx-2">通常版へ</a>
    </div>
  </nav>
</template>
<script>
/* global g_admin, g_sub_admin */
export default {
  data() {
    return {
      location,
      admin: g_admin,
      sub_admin: g_sub_admin,
      list: [
        { alias: 'top', name: 'TOP' },
        { alias: 'bbs', name: '掲示板' },
        { alias: 'schedule', name: '予定表' },
        { alias: 'result', name: '大会結果' },
        { alias: 'wiki', name: 'Wiki' },
        { alias: 'album', name: 'アルバム' },
        { alias: 'addrbook', name: '名簿' },
      ],
      publicList: [
        // { alias: 'top', name: 'TOP' },
        { alias: 'bbs', name: '掲示板' },
        { alias: 'schedule', name: '予定表' },
        // { alias: 'wiki', name: 'Wiki' },
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
