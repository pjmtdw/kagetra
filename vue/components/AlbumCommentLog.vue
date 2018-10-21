<template>
  <main id="container" class="mx-auto">
    <div class="d-flex flex-column flex-md-row align-items-center mt-3">
      <nav>
        <ul class="pagination mb-0">
          <router-link to="/" tag="li" class="page-item" exact-active-class="active">
            <a href="#" class="page-link" @click.prevent>アルバム</a>
          </router-link>
          <router-link to="/comment_log" tag="li" class="page-item" exact-active-class="active">
            <a href="#" class="page-link" @click.prevent>コメント履歴</a>
          </router-link>
          <router-link to="/stat" tag="li" class="page-item" exact-active-class="active">
            <a href="#" class="page-link" @click.prevent>統計</a>
          </router-link>
        </ul>
      </nav>
    </div>
    <div class="d-flex justify-content-between mt-4">
      <button class="btn btn-primary" :disabled="page === 1" @click="page -= 1">Previous</button>
      <button class="btn btn-primary" :disabled="data.next_page === null" @click="page += 1">Next</button>
    </div>
    <div class="comment-log d-flex flex-wrap mt-3">
      <div v-for="item in data.list" class="p-2">
        <div class="card shadow-sm">
          <router-link :to="`/${item.id}`">
            <img :src="`/static/album/thumb/${item.thumb.id}`" class="card-img-top" :width="item.thumb.width" :height="item.thumb.height">
          </router-link>
          <div class="card-body p-3">
            <h6 class="card-title">
              <span>{{ item.log.user_name }}</span>
              <span class="date">@{{ item.log.date }}</span>
            </h6>
            <p class="card-text" v-html="item.diff_html"/>
          </div>
        </div>
      </div>
    </div>
  </main>
</template>
<script>
export default {
  data() {
    return {
      page: 1,
      data: {},
    };
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
      const params = this.page > 1 ? { page: this.page } : {};
      axios.get('/album/all_comment_log', { params }).then((res) => {
        this.data = res.data;
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

.date {
  color: maroon;
}

.comment-log {
  height: 80vh;
  overflow-y: auto;
  -webkit-overflow-scrolling: touch;
}
</style>
