<template>
  <main id="container" class="mx-auto">
    <!-- nav, 選手名検索 -->
    <div class="container my-2">
      <div class="row">
        <nav id="nav-result-pages" class="col-12 col-md-8">
          <ul class="pagination justify-content-center justify-content-md-start">
            <li class="page-item"><router-link class="page-link p-1 p-sm-2" to="/">大会結果</router-link></li>
            <li class="page-item"><router-link class="page-link p-1 p-sm-2" to="/list">大会一覧</router-link></li>
            <li class="page-item"><router-link class="page-link p-1 p-sm-2" to="/record">個人記録</router-link></li>
            <li class="page-item active"><span class="page-link p-1 p-sm-2">昇級履歴</span></li>
            <li class="page-item"><router-link class="page-link p-1 p-sm-2" to="/ranking">ランキング</router-link></li>
          </ul>
        </nav>
        <div class="col-12 col-md-4 mt-2 mt-md-0">
          <div class="input-group justify-content-center">
            <div class="input-group-prepend">
              <span class="input-group-text">検索</span>
            </div>
            <PlayerSearch :append="true" :link="true" :clear="true" placeholder="選手名検索"/>
          </div>
        </div>
      </div>
    </div>
    <!-- 最近 -->
    <div v-if="recent" class="list-group">
      <div v-for="x in list" class="list-group-item">
        <h6 class="text-muted">{{ x.event.date }}</h6>
        <div class="d-flex flex-row">
          <span>
            <router-link class="card-link" :to="`/record/${x.name}`">{{ x.name }}</router-link>
            さんが
            <router-link class="card-link ml-0" :to="`/${x.event.id}`">{{ x.event.name }}</router-link>
            の
            {{ x.class_name }}
            で
            {{ x.prize }}
            でした
          </span>
          <button class="btn btn-sm btn-outline-success ml-auto" :data-target="`edit_attr_${x.event.id}_${x.user_id}`" @click="toggleEditAttr">属性編集</button>
        </div>
        <div :ref="`edit_attr_${x.event.id}_${x.user_id}`" class="jumbotron collapse p-3 mt-2 mb-1">
          <div class="d-flex flex-row flex-wrap">
            <div v-for="(a, i) in attrs" class="input-group w-auto mr-1">
              <div class="input-group-prepend">
                <span class="input-group-text">{{ a[0] }}: {{ x.attrs[i][0] }} &rarr;</span>
              </div>
              <select v-model="x.attrs[i][1]" class="custom-select">
                <option v-for="y in a[1]" :key="y[1]" :value="y[1]">{{ y[0] }}</option>
              </select>
            </div>
            <div class="w-100 d-sm-none"/>
            <button class="btn btn-success mt-2 mt-sm-0" @click="changeAttr(x)">変更</button>
          </div>
        </div>
      </div>
    </div>
  </main>
</template>
<script>
import PlayerSearch from './subcomponents/PlayerSearch.vue';

export default {
  components: {
    PlayerSearch,
  },
  props: {
    recent: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      attrs: null,
      list: [],
    };
  },
  computed: {
  },
  watch: {
    recent() {
      this.fetch();
    },
  },
  created() {
    this.fetch();
  },
  methods: {
    fetch() {
      axios.get('/api/result_promotion/recent').then((res) => {
        this.attrs = res.data.attrs;
        this.list = _.map(res.data.list, (x) => {
          x.attrs = [];
          _.each(this.attrs, (a) => {
            x.attrs.push(_.clone(_.find(a[1], v => _.includes(x.attr_values, v[1]))));
          });
          return x;
        });
      });
    },
    toggleEditAttr(event) {
      $(this.$refs[event.target.getAttribute('data-target')]).toggleClass('show');
    },
    changeAttr(x) {
      const data = { values: _.map(x.attrs, v => v[1]) };
      axios.post(`/api/user/change_attr/${x.event.id}/${x.user_id}`, data).then(() => {
        $.notify('変更しました');
      }).catch(() => {
        $.notify('danger', '変更に失敗しました');
      });
    },
  },
};
</script>
<style lang="scss" scoped>
@import '../sass/result_common.scss';

#container {
  width: 100%;
  max-width: 860px;
}

table.summary {
  border-collapse: separate;
  border-spacing: 0px;
  @media screen and (max-width: 575px) {
    font-size: 10px;
  }
  td {
    padding: .1rem .3rem;
  }
}
</style>
