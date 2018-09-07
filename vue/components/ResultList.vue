<template>
  <main id="container" class="mx-auto">
    <div class="container my-2">
      <div class="row">
        <nav id="nav-result-pages" class="col-12 col-md-8">
          <ul class="pagination justify-content-center justify-content-md-start">
            <li class="page-item"><router-link class="page-link p-1 p-sm-2" to="/">大会結果</router-link></li>
            <li class="page-item active"><span class="page-link p-1 p-sm-2">大会一覧</span></li>
            <li class="page-item"><router-link class="page-link p-1 p-sm-2" to="/list">個人記録</router-link></li>
            <li class="page-item"><router-link class="page-link p-1 p-sm-2" to="/list">昇級履歴</router-link></li>
            <li class="page-item"><router-link class="page-link p-1 p-sm-2" to="/list">ランキング</router-link></li>
          </ul>
        </nav>
      </div>
    </div>
    <nav class="nav nav-pills flex-row flex-wrap" role="tablist">
      <router-link v-for="y in years" :key="y" :to="`/list/${y}`" class="nav-link" :class="{active: (y == year)}" role="tab">
        {{ y }}
      </router-link>
    </nav>
    <div class="container border">
      <div v-for="(ct, i) in list" :key="ct.id" class="row justify-content-center" :class="[i % 2 === 1 ? 'bg-light' : 'bg-white']">
        <div class="col-3 col-lg-2 d-flex align-items-center">{{ ct.date }}</div>
        <div class="col-3 col-lg-2 d-flex align-items-center">
          <div>
            <router-link :to="`/${ct.id}`" class="card-link">{{ ct.name }}</router-link>
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
  </main>
</template>
<script>
export default {
  props: {
    year: {
      type: String,
      default: (new Date()).getFullYear().toString(),
    },
  },
  data() {
    return {
      list: [],
      years: [],
    };
  },
  watch: {
    year(val) {
      this.fetch(val);
    },
  },
  created() {
    this.fetch(this.year);
  },
  mounted() {
  },
  updated() {
  },
  methods: {
    fetch(year) {
      const url = `/api/result_list/year/${year}`;
      axios.get(url).then((res) => {
        this.list = res.data.list;
        this.years = _.rangeRight(res.data.minyear, res.data.maxyear + 1);
      }).catch(() => {
        this.$_notify('danger', '大会一覧の取得に失敗しました');
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
</style>
