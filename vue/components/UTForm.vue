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
      <div v-for="item in posts.list" :key="item.id" class="card mt-2">
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
            <span v-if="item.status >= 2">
              <span>{{ statuses[item.status].text }} (by {{ item.status_change_user }})</span>
              <button v-if="in2hours(item.status_change_at)" class="btn btn-outline-secondary" @click="updateStatus(item, 1)">取消</button>
            </span>
            <span v-else>
              <button class="btn btn-primary" @click="updateStatus(item, 2)">{{ statuses[2].text }}</button>
              <button class="btn btn-secondary" @click="updateStatus(item, 3)">{{ statuses[3].text }}</button>
            </span>
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
      statuses: [
        null,
        { name: 'notyet', text: '未完了' },
        { name: 'done', text: '返信済み' },
        { name: 'ignore', text: '返信不要' },
      ],
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
    in2hours(dateString) {
      if (!dateString) return false;
      const d = Date.parse(dateString);
      console.log(d, _.now());
      return _.now() - d < 1000 * 60 * 60 * 2;
    },
    updateStatus(item, status) {
      axios.post(`/ut_karuta/update_status/${item.id}/${this.statuses[status].name}`).then(() => {
        this.fetch();
      }).catch(this.$_makeOnFail('変更に失敗しました'));
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
