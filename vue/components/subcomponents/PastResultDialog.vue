<template>
  <div class="modal fade">
    <div class="modal-dialog modal-lg">
      <div v-if="cached" class="modal-content">
        <div class="modal-header">
          <h5 v-if="!editing" class="modal-title">{{ name }}</h5>
          <input v-else type="text" class="form-control" v-model="edit.name">
          <button type="button" class="close" data-dismiss="modal">
            <span aria-hidden="true">&times;</span>
          </button>
        </div>
        <div class="modal-body">
          <div v-if="description != null" class="card bg-light">
            <div class="card-header d-flex flex-row align-items-center">
              <h5 class="text-black-50 mb-0">大会情報</h5>
              <button v-if="!editing" class="btn btn-success ml-auto" @click="startEdit">編集</button>
              <template v-else>
                <button class="btn btn-outline-secondary ml-auto" @click="editing = false">キャンセル</button>
                <button class="btn btn-success ml-2" @click="save">保存</button>
              </template>
            </div>
            <div class="card-body">
              <div v-if="!editing" class="pre">{{ description }}</div>
              <textarea v-else v-model="edit.description" class="form-control" :rows="rows"/>
            </div>
          </div>
          <hr v-if="description != null">
          <nav v-if="pages > 1" class="pl-2">
            <ul class="pagination">
              <li v-for="p in pages" :key="p" class="page-item" :class="{'active': p == page}">
                <a class="page-link" href="#" @click.prevent="page = p">{{ p }}</a>
              </li>
            </ul>
          </nav>
          <!-- 大会一覧 -->
          <div class="container border">
            <div v-for="(ct, i) in list" :key="ct.id" class="row justify-content-center" :class="[i % 2 === 1 ? 'bg-light' : 'bg-white']">
              <div class="col-2 d-flex align-items-center">{{ ct.date }}</div>
              <div class="col-4 col-lg-2 d-flex align-items-center">
                <div>
                  <span v-if="ct.official">&spades;</span>
                  <span v-else class="text-success">&clubs;</span>
                  <router-link v-if="gRouteName === 'result'" :to="`/${ct.id}`" class="card-link">{{ ct.name }}</router-link>
                  <a v-else :href="`/result#/${ct.id}`" class="card-link">{{ ct.name }}</a>
                  <div>{{ ct.win }}勝{{ ct.lose }}敗({{ ct.user_count }}人)</div>
                </div>
              </div>
              <div class="col-6 col-lg-4 d-flex align-items-center">
                <div>
                  <template v-for="p in ct.prizes">
                    <div v-if="p.type === 'team'" class="font-weight-bold">
                      {{ p.class_name }} {{ p.prize }} {{ p.name }}
                    </div>
                    <div v-else-if="p.point > 0" :class="{ 'text-success': p.promotion === 'rank_up' }">
                      {{ p.class_name }} {{ p.prize }} {{ p.name }} [{{ p.point }}pt, {{ p.point_local }}kpt]
                    </div>
                    <div v-else-if="p.point_local > 0" :class="{ 'text-success': p.promotion === 'rank_up' }">
                      {{ p.class_name }} {{ p.prize }} {{ p.name }} [{{ p.point_local }}kpt]
                    </div>
                    <div v-else :class="{ 'text-success': p.promotion === 'rank_up' }">
                      {{ p.class_name }} {{ p.prize }} {{ p.name }}
                    </div>
                  </template>
                </div>
              </div>
            </div>
          </div>
        </div>
        <div class="modal-footer">
          <button type="button" class="btn btn-secondary" data-dismiss="modal">閉じる</button>
        </div>
      </div>
    </div>
  </div>
</template>
<script>
export default {
  props: {
    id: {
      type: Number,
      required: true,
    },
  },
  data() {
    return {
      $dialog: null,
      cached: false,

      page: 1,
      description: null,
      list: null,
      name: null,
      pages: 1,

      editing: false,
      edit: null,
    };
  },
  computed: {
    rows() {
      return _.max([this.description.split('\n').length, 4]);
    },
  },
  watch: {
    page() {
      this.fetch();
    },
    $route() {
      this.$dialog.modal('hide');
    },
  },
  mounted() {
    this.$dialog = $(this.$el);
    this.$dialog.on('hideen.bs.modal', () => {
      this.editing = false;
    });
  },
  methods: {
    open() {
      this.page = 1;
      if (!this.cached) this.fetch();
      else this.$dialog.modal('show');
    },
    fetch() {
      const data = this.page === 1 ? null : { params: { page: this.page } };
      axios.get(`/result/group/${this.id}`, data).then((res) => {
        this.cached = true;
        _.forEach(res.data, (v, key) => {
          this[key] = v;
        });
        this.$dialog.modal('show');
      }).catch(this.$_makeOnFail('過去の結果の取得に失敗しました'));
    },
    startEdit() {
      this.editing = true;
      this.edit = {
        name: this.name,
        description: this.description,
      };
    },
    save() {
      axios.put(`/event/group/${this.id}`, this.edit).then(() => {
        this.name = this.edit.name;
        this.description = this.edit.description;
        this.editing = false;
      }).catch(this.$_makeOnFail('保存に失敗しました'));
    },
  },
};
</script>
