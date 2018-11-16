<template>
  <main id="container" class="mx-auto">
    <div class="mt-3">
      <a href="https://ut-karuta.bushidoo.com">東大かるた会公式サイト</a> の問い合わせフォームの結果はここに来ます. <br>
      返信済みフラグは景虎内で共有されるので，メールで返信をした人は「返信済み」を押すか，返信しなくてもいいなら「返信不要」を押して下さい．
    </div>
    <nav v-if="posts" class="mt-3">
      <ul class="pagination justify-content-center">
        <li v-for="i in pages" :key="i" class="page-item" :class="{ active: i == page }">
          <a class="page-link" :href="`#/${i}`">{{ i }}</a>
        </li>
      </ul>
    </nav>
    <div v-if="posts" class="mt-3">
      <div v-for="item in posts.list" :key="item.id" class="card mt-1">
        <div class="card-body">
          <div class="card-title mb-2">
            <span>{{ item.name }}</span>
            <span>&lt;</span>
            <a :href="`mailto:${item.mail}`">{{ item.mail }}</a>
            <span>&gt;</span>
          </div>
          <div class="card-subtitle mb-1">
            {{ item.created_at.slice(0, -6) }}
          </div>
          <div class="card-subtitle">
            {{ statuses[item.status] }} (by {{ item.status_change_user }})
          </div>
          <hr>
          <div class="pre">{{ item.body }}</div>
        </div>
      </div>
    </div>
    <nav v-if="posts" class="mt-3">
      <ul class="pagination justify-content-center">
        <li v-for="i in pages" :key="i" class="page-item" :class="{ active: i == page }">
          <a class="page-link" :href="`#/${i}`">{{ i }}</a>
        </li>
      </ul>
    </nav>
  </main>
</template>
<script>
export default {
  props: {
    page: {
      type: String,
      default: '1',
    },
  },
  data() {
    return {
      statuses: [null, '未完了', '返信不要', '返信済み'],
      posts: null,
    };
  },
  computed: {
    pages() {
      if (this.posts === null) return null;
      return _.range(1, this.posts.page_count + 1);
    },
  },
  watch: {
    page() {
      this.fetch();
    },
  },
  created() {
    this.fetch();
  },
  methods: {
    fetch() {
      axios.get('/ut_karuta/list', { params: { page: this.page } }).then((res) => {
        this.posts = res.data;
      });
    },
  },
};
</script>
<style lang="scss" scoped>
#container {
  width: 100%;
  max-width: 750px;
}
</style>
