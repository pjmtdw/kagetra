<template>
  <main id="container" class="mx-auto">
    <div class="d-flex mt-3">
      <div class="input-group w-auto ml-auto">
        <input v-model.lazy="query" type="search" class="form-control w-auto">
        <div class="input-group-append">
          <button class="btn btn-secondary">検索</button>
        </div>
      </div>
    </div>
    <!-- pagination -->
    <nav v-if="data.pages > 1">
      <div class="text-center">
        <span class="text-muted">(全{{ data.count }}件)</span>
      </div>
      <ul class="pagination justify-content-center">
        <li v-for="p in data.pages" :key="p" class="page-item" :class="{ active: page === p }">
          <a href="#" class="page-link" @click.prevent="page = p">{{ p }}</a>
        </li>
      </ul>
    </nav>
    <!-- 写真 -->
    <div class="d-flex flex-wrap mt-3">
      <div v-for="item in data.list" class="p-2">
        <div class="card shadow-sm">
          <router-link :to="`/${item.id}`">
            <img :src="`/static/album/thumb/${item.thumb.id}`" :class="item.no_comment ? 'card-img' : 'card-img-top'" :width="item.thumb.width" :height="item.thumb.height">
          </router-link>
        </div>
      </div>
    </div>
    <!-- pagination -->
    <nav v-if="data.pages > 1">
      <ul class="pagination justify-content-center">
        <li v-for="p in data.pages" :key="p" class="page-item" :class="{ active: page === p }">
          <a href="#" class="page-link" @click.prevent="page = p">{{ p }}</a>
        </li>
      </ul>
    </nav>
  </main>
</template>
<script>
export default {
  props: {
    q: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      query: null,
      page: 1,
      data: {},
    };
  },
  watch: {
    query() {
      this.fetch();
    },
    page() {
      this.fetch();
    },
  },
  created() {
    this.query = this.q;
    this.fetch();
  },
  methods: {
    fetch() {
      const data = { qs: this.query };
      if (this.page > 1) data.page = this.page;
      axios.post('/album/search', data).then((res) => {
        this.data = res.data;
      }).catch(this.$_makeOnFail('結果の取得に失敗しました'));
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
