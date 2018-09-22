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
            <li class="page-item"><router-link class="page-link p-1 p-sm-2" to="/promotion">昇級履歴</router-link></li>
            <li class="page-item active"><span class="page-link p-1 p-sm-2">ランキング</span></li>
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
    <!-- 条件 -->
    <form class="ml-1">
      <div>期間</div>
      <div class="form-inline">
        <input v-model.lazy="start" type="text" class="form-control" style="width: 7rem;">
        <span class="mx-1">&#12316;</span>
        <input v-model.lazy="end" type="text" class="form-control" style="width: 7rem;">
        <div class="dropdown ml-2">
          <button class="btn btn-secondary dropdown-toggle" type="button" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false" data-boundary="window" data-flip="false">
            年
          </button>
          <div class="dropdown-menu">
            <div class="dropdown-item">全期間</div>
            <div v-for="y in years" :key="y" class="dropdown-item">{{ y }}</div>
          </div>
        </div>
      </div>
      <div class="form-row mt-2 mx-0">
        <div class="form-group mr-3">
          <div>集計1</div>
          <select v-model="key1" class="custom-select">
            <option v-for="(v, k) in keys" :key="k" :value="k">{{ v }}</option>
          </select>
        </div>
        <div class="form-group mr-3">
          <div>集計2</div>
          <select v-model="key2" class="custom-select">
            <option v-for="(v, k) in keys" :key="k" :value="k">{{ v }}</option>
          </select>
        </div>
        <div class="form-group">
          <div>フィルタ</div>
          <select v-model="filter" class="custom-select">
            <option v-for="(v, k) in filters" :key="k" :value="k">{{ v }}</option>
          </select>
        </div>
      </div>
    </form>
    <!-- ランキング -->
    <div v-if="meta !== null" class="alert alert-light m-1 p-1">
      <dl class="row mb-0">
        <dt class="col-3 col-sm-2 col-lg-1">期間</dt>
        <dd class="col-9 col-sm-10 col-lg-11 mb-1">{{ meta.start }} &sim; {{ meta.end }}</dd>
        <dt class="col-3 col-sm-2 col-lg-1">フィルタ</dt>
        <dd class="col-9 col-sm-10 col-lg-11 mb-1">{{ filters[meta.filter] }}</dd>
        <dt class="col-3 col-sm-2 col-lg-1">合計</dt>
        <dd class="col-9 col-sm-10 col-lg-11 mb-0">{{ keys[meta.key1.name] }}: {{ meta.key1.sum }}, {{ keys[meta.key2.name] }}: {{ meta.key2.sum }}</dd>
      </dl>
    </div>
    <table v-if="meta !== null" class="table table-sm table-striped bg-white border w-auto px-2">
      <thead>
        <tr>
          <th>順位</th>
          <th>名前</th>
          <th>{{ keys[meta.key1.name] }}</th>
          <th>{{ keys[meta.key2.name] }}</th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="x in ranking">
          <td>{{ x.rank }}</td>
          <td>
            <router-link :to="`/record/${x.name}`" class="card-link">{{ x.name }}</router-link>
          </td>
          <td>{{ x.key1 }}</td>
          <td>{{ x.key2 }}</td>
        </tr>
      </tbody>
    </table>
  </main>
</template>
<script>
import PlayerSearch from './subcomponents/PlayerSearch.vue';

export default {
  components: {
    PlayerSearch,
  },
  props: {
    _start: {
      type: String,
      default() {
        const d = new Date();
        return `${d.getFullYear() - 1}-${d.getMonth() + 1}`;
      },
    },
    _end: {
      type: String,
      default() {
        const d = new Date();
        return `${d.getFullYear()}-${d.getMonth() + 1}`;
      },
    },
    _key1: {
      type: String,
      default: 'win',
    },
    _key2: {
      type: String,
      default: 'contest_num',
    },
    _filter: {
      type: String,
      default: 'official',
    },
  },
  data() {
    return {
      created: false,
      // 条件
      start: null,
      end: null,
      key1: null,
      key2: null,
      filter: null,
      // データ
      keys: {
        win: '勝ち数',
        contest_num: '大会出場数',
        win_percent: '勝率',
        point: 'ポイント',
        point_local: '会内ポイント',
      },
      filters: {
        '': 'なし',
        official: '公認大会',
        a: 'A級公認個人戦',
        b: 'B級公認個人戦',
        c: 'C級公認個人戦',
        d: 'D級公認個人戦',
        e: 'E級公認個人戦',
        f: 'F級公認個人戦',
        g: 'G級公認個人戦',
      },
      years: null,
      meta: null,
      ranking: null,
    };
  },
  computed: {
    query() {
      return {
        start: this.start,
        end: this.end,
        key1: this.key1,
        key2: this.key2,
        filter: this.filter,
      };
    },
  },
  watch: {
    start(val) {
      if (_.isNaN(new Date(val).getTime())) return;
      this.change();
    },
    end(val) {
      if (_.isNaN(new Date(val).getTime())) return;
      this.change();
    },
    key1() {
      this.change();
    },
    key2() {
      this.change();
    },
    filter() {
      this.change();
    },
  },
  mounted() {
    this.start = this._start;
    this.end = this._end;
    this.key1 = this._key1;
    this.key2 = this._key2;
    this.filter = this._filter;
    axios.get('/api/result_ranking/year').then((res) => {
      this.years = _.rangeRight(res.data.minyear, res.data.maxyear + 1);
      this.fetch();
    });
    this.$nextTick(() => { this.created = true; });
  },
  methods: {
    fetch() {
      const data = {
        start: this.start,
        end: this.end,
        key1: this.key1,
        key2: this.key2,
        filter: this.filter,
      };
      axios.post('/api/result_ranking/search', data).then((res) => {
        this.meta = res.data.meta;
        this.ranking = res.data.ranking;
      });
    },
    change() {
      if (!this.created) return;
      this.$router.push({ query: this.query });
      this.fetch();
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

dl {
  font-size: 10px;
}
</style>
