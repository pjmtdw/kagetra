<template>
  <main id="container" class="container mx-auto">
    <div class="row d-flex flex-column flex-md-row align-items-center mt-3">
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
    <div class="row mt-4">
      <div class="col-6 pl-0 pr-1">
        <div class="card">
          <div class="card-header">アップロード枚数</div>
          <table class="table mb-0">
            <tr v-for="u in data.uploader_stat">
              <template v-if="u[3]">
                <th>{{ u[0] }}</th>
                <th>{{ data.uploader_names[u[2]] }}</th>
                <th>{{ u[1] }}</th>
              </template>
              <template v-else>
                <th>{{ u[0] }}</th>
                <td>{{ data.uploader_names[u[2]] }}</td>
                <td>{{ u[1] }}</td>
              </template>
            </tr>
          </table>
        </div>
      </div>
      <div class="col-6 pl-1 pr-0">
        <div class="card">
          <div class="card-header">タグ</div>
          <table class="table mb-0">
            <tr v-for="u in data.tag_stat">
              <template v-if="u[3]">
                <th>{{ u[0] }}</th>
                <th>{{ u[2] }}</th>
                <th>{{ u[1] }}</th>
              </template>
              <template v-else>
                <th>{{ u[0] }}</th>
                <td>{{ u[2] }}</td>
                <td>{{ u[1] }}</td>
              </template>
            </tr>
          </table>
        </div>
      </div>
    </div>
  </main>
</template>
<script>
export default {
  data() {
    return {
      data: {},
    };
  },
  created() {
    this.fetch();
  },
  methods: {
    fetch() {
      axios.get('/album/stat').then((res) => {
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
</style>
