<template>
  <div id="container" class="mx-auto">
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
      <router-link v-for="y in years" :to="`/list/${y}`" :key="y" class="nav-link" :class="{active: (y == year)}" role="tab">
        {{ y }}
      </router-link>
    </nav>
    <div class="container border">
      <div v-for="(ct, i) in list" :key="ct.id" class="row justify-content-center" :class="[i % 2 === 1 ? 'bg-light' : 'bg-white']">
        <div class="col-3 col-lg-2">{{ ct.date }}</div>
        <div class="col-3 col-lg-2">{{ ct.name }}</div>
        <div class="col-6 col-lg-4">{{ ct.prizes }}</div>
      </div>
    </div>
  </div>
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
        $.notify('danger', '大会一覧の取得に失敗しました');
      });
    },
  },
};
</script>
<style lang="scss" scoped>
@import '../sass/common.scss';
@import '../sass/result_common.scss';

#container {
  width: 100%;
  max-width: 860px;
}
</style>
