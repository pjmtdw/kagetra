<template>
  <main id="container" class="mx-auto">
    <!-- nav, 検索 -->
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
      <div class="d-flex flex-row ml-md-auto mt-2 mt-md-0">
        <button class="btn btn-success" data-toggle="modal" data-target="#new_album_dialog">新規作成</button>
        <div class="input-group w-auto ml-2">
          <input v-model="query" type="search" class="form-control w-auto" @keydown.enter="search">
          <div class="input-group-append">
            <button class="btn btn-secondary" @click="search">検索</button>
          </div>
        </div>
      </div>
    </div>
    <!-- 新着/一覧 -->
    <div class="container">
      <div class="row mt-4">
        <div class="col-12 col-md-6 pt-2">
          <h5 class="mb-1">新着</h5>
          <div class="card shadow-sm">
            <div class="list-group list-group-flush">
              <router-link v-for="g in data.recent" :key="g.id" :to="`/group/${g.id}`" class="list-group-item list-group-item-action">
                <div class="d-flex justify-content-between">
                  <div class="d-flex flex-row flex-grow-1">
                    <div>
                      <h6 class="font-weight-bold mb-0">{{ g.name || '(タイトル無し)' }}</h6>
                      <small v-if="g.no_tag" class="text-muted">タグ無し {{ g.no_tag }}%</small>
                      <small v-if="g.no_comment" class="text-muted">コメント無し {{ g.no_comment }}%</small>
                    </div>
                    <small class="ml-auto mr-4 align-self-start">{{ g.start_at }}</small>
                  </div>
                  <div class="item-count align-self-start text-right">
                    <span class="badge badge-primary badge-pill">{{ g.item_count }}</span>
                  </div>
                </div>
              </router-link>
            </div>
          </div>
        </div>
        <div class="col-12 col-md-6 pt-2">
          <h5 class="mb-1">一覧</h5>
          <div class="card shadow-sm">
            <div class="list-group list-group-flush">
              <template v-if="!selectedYear">
                <a v-for="y in data.list" :key="y.year" href="#" class="list-group-item list-group-item-action d-flex" @click.prevent="loadYear(y.year)">
                  <span v-if="y.year">{{ y.year }}年</span>
                  <span v-else>不明</span>
                  <span class="badge badge-primary badge-pill ml-auto">{{ y.item_count }}</span>
                </a>
              </template>
              <template v-else>
                <a href="#" class="list-group-item list-group-item-action list-group-item-secondary text-primary font-weight-bold" @click.prevent="selectedYear = null">&lt;</a>
                <router-link v-for="g in yearData" :key="g.id" :to="`/group/${g.id}`" class="list-group-item list-group-item-action">
                  <div class="d-flex justify-content-between">
                    <div class="d-flex flex-row flex-grow-1">
                      <div>
                        <h6 class="font-weight-bold mb-0">{{ g.name || '(タイトル無し)' }}</h6>
                        <small v-if="g.no_tag" class="text-muted">タグ無し {{ g.no_tag }}%</small>
                        <small v-if="g.no_comment" class="text-muted">コメント無し {{ g.no_comment }}%</small>
                      </div>
                      <small class="ml-auto mr-4 align-self-start">{{ g.start_at }}</small>
                    </div>
                    <div class="item-count align-self-start text-right">
                      <span class="badge badge-primary badge-pill">{{ g.item_count }}</span>
                    </div>
                  </div>
                </router-link>
              </template>
            </div>
            <div v-if="!selectedYear && data.total" class="card-footer">
              {{ data.total }}枚
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- 新規作成 -->
    <div id="new_album_dialog" class="modal fade">
      <div class="modal-dialog">
        <div class="modal-content">
          <div class="modal-header">
            <h5 class="modal-title">新規作成</h5>
            <button class="close" data-dismiss="modal">
              <span>&times;</span>
            </button>
          </div>
          <div class="modal-body">
            <form>
              <div class="form-group">
                <label class="w-100">
                  タイトル
                  <input v-model="newAlbum.name" type="text" class="form-control mb-2" placeholder="タイトル">
                </label>
                <label class="w-100">
                  場所
                  <input v-model="newAlbum.place" type="text" class="form-control mb-2" placeholder="場所">
                </label>
                <label class="w-100">
                  開始日
                  <input v-model="newAlbum.start_at" type="date" class="form-control mb-2" placeholder="開始日(YYYY-MM-DD)">
                </label>
                <label class="w-100">
                  終了日
                  <input v-model="newAlbum.end_at" type="date" class="form-control mb-2" placeholder="終了日(YYYY-MM-DD)">
                </label>
                <label class="w-100">
                  コメント
                  <input v-model="newAlbum.comment" type="text" class="form-control mb-2" placeholder="コメント">
                </label>
              </div>
            </form>
          </div>
          <div class="modal-footer">
            <button class="btn btn-outline-secondary ml-auto" data-dismiss="modal">キャンセル</button>
            <button class="btn btn-success" @click="create">作成</button>
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
      query: null,
      data: {},
      selectedYear: null,
      yearData: null,
      newAlbum: {
        name: null,
        place: null,
        start_at: null,
        end_at: null,
        comment: null,
      },
    };
  },
  created() {
    this.fetch();
  },
  methods: {
    fetch() {
      axios.get('/album/years').then((res) => {
        this.data = res.data;
      }).catch(this.$_makeOnFail('情報の取得に失敗しました'));
    },
    search() {
      if (_.isEmpty(this.query)) return;
      this.$router.push(`/search/${this.query}`);
    },
    loadYear(year) {
      axios.get(`/album/year/${year || '_else_'}`).then((res) => {
        this.selectedYear = year;
        this.yearData = res.data.list;
      });
    },
    create() {
      axios.post('/album/group', this.newAlbum).then(() => {
        this.fetch();
        $('#new_album_dialog').modal('hide');
      }).catch(this.$_makeOnFail('作成に失敗しました'));
    },
  },
};
</script>
<style lang="scss" scoped>
#container {
  width: 100%;
  max-width: 750px;
}

.item-count {
  width: 10%;
}
</style>
