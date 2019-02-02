<template>
  <main id="container" class="mx-auto">
    <nav class="nav nav-pills mt-3">
      <router-link class="nav-link" to="/ranking" exact-active-class="active">ランキング</router-link>
      <router-link class="nav-link" to="/weekly" exact-active-class="active">今週</router-link>
      <router-link class="nav-link" to="/history" exact-active-class="active">履歴</router-link>
    </nav>
    <div v-if="page === 'ranking' && ranking" class="container mt-2">
      <div class="row">
        <div class="col-12 col-md-4">
          <div class="text-center">今月</div>
          <table class="table table-striped table-sm border bg-white">
            <tbody>
              <tr v-for="r in ranking.cur.ranking" :key="r.user_id">
                <td :class="{ 'font-weight-bold': ranking.cur.myinfo.user_id === r.user_id }">{{ r.rank }}</td>
                <td :class="{ 'font-weight-bold': ranking.cur.myinfo.user_id === r.user_id }">{{ r.count }}</td>
                <td :class="{ 'font-weight-bold': ranking.cur.myinfo.user_id === r.user_id }">{{ ranking.names[r.user_id] }}</td>
                <td :class="{ 'font-weight-bold': ranking.cur.myinfo.user_id === r.user_id }">[{{ ranking.one_day[r.user_id] }}]</td>
              </tr>
              <tr v-if="!isRankedCur">
                <td class="font-weight-bold">{{ ranking.cur.myinfo.rank }}</td>
                <td class="font-weight-bold">{{ ranking.cur.myinfo.count }}</td>
                <td class="font-weight-bold">{{ ranking.names[ranking.cur.myinfo.user_id] }}</td>
                <td class="font-weight-bold">[{{ ranking.one_day[ranking.cur.myinfo.user_id] || 0 }}]</td>
              </tr>
            </tbody>
          </table>
        </div>
        <div class="col-12 col-md-4">
          <div class="text-center">先月</div>
          <table class="table table-striped table-sm border bg-white">
            <tbody>
              <tr v-for="r in ranking.prev.ranking" :key="r.user_id">
                <td :class="{ 'font-weight-bold': ranking.prev.myinfo.user_id === r.user_id }">{{ r.rank }}</td>
                <td :class="{ 'font-weight-bold': ranking.prev.myinfo.user_id === r.user_id }">{{ r.count }}</td>
                <td :class="{ 'font-weight-bold': ranking.prev.myinfo.user_id === r.user_id }">{{ ranking.names[r.user_id] }}</td>
              </tr>
              <tr v-if="!isRankedPrev">
                <td class="font-weight-bold">{{ ranking.cur.myinfo.rank }}</td>
                <td class="font-weight-bold">{{ ranking.cur.myinfo.count }}</td>
                <td class="font-weight-bold">{{ ranking.names[ranking.cur.myinfo.user_id] }}</td>
              </tr>
            </tbody>
          </table>
        </div>
        <div class="col-12 col-md-4">
          <div class="text-center">総計</div>
          <table class="table table-striped table-sm border bg-white">
            <tbody>
              <tr v-for="r in ranking.total.ranking" :key="r.user_id">
                <td :class="{ 'font-weight-bold': ranking.total.myinfo.user_id === r.user_id }">{{ r.rank }}</td>
                <td :class="{ 'font-weight-bold': ranking.total.myinfo.user_id === r.user_id }">{{ r.count }}</td>
                <td :class="{ 'font-weight-bold': ranking.total.myinfo.user_id === r.user_id }">{{ ranking.names[r.user_id] }}</td>
              </tr>
              <tr v-if="!isRankedTotal">
                <td class="font-weight-bold">{{ ranking.total.myinfo.rank }}</td>
                <td class="font-weight-bold">{{ ranking.total.myinfo.count }}</td>
                <td class="font-weight-bold">{{ ranking.names[ranking.total.myinfo.user_id] }}</td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>
    <div v-else-if="page === 'weekly' && weekly" class="mt-2">
      <template v-for="day in weekly.list">
        <div>{{ day[0] }}</div>
        <table class="table table-striped table-sm border bg-white w-auto">
          <tbody>
            <tr v-for="h in day[1]" :key="h.hour">
              <td>{{ h.hour }}時</td>
              <td>
                <span class="bar mylog" :style="`width: ${h.mylog * 10}px;`">&nbsp;</span><!-- 隙間を埋める
             --><span class="bar" :class="h.total === weekly.total_max ? 'total-max' : 'total'" :style="`width: ${(h.total - h.mylog) * 10}px;`">&nbsp;</span>
                <span v-if="h.total === weekly.total_max">{{ weekly.total_max }}</span>
              </td>
            </tr>
          </tbody>
        </table>
      </template>
    </div>
    <div v-else-if="page === 'history' && history" class="mt-2">
      <table class="table table-striped table-sm border bg-white">
        <thead>
          <th>年月</th>
          <th>総数</th>
          <th colspan="5">TOP5</th>
          <th>貴方</th>
          <th>順位</th>
        </thead>
        <tbody>
          <tr v-for="m in history.list" :key="m[0]">
            <td>{{ m[0] }}</td>
            <td>{{ m[1].count }}</td>
            <td v-for="(v, i) in m[1].top" :class="{ 'font-weight-bold': m[1].user && i == m[1].user.rank }">{{ v }}</td>
            <td>{{ m[1].user ? m[1].user.count : 0 }}</td>
            <td>{{ m[1].user ? m[1].user.rank : -1 }}</td>
          </tr>
        </tbody>
      </table>
    </div>
  </main>
</template>
<script>
export default {
  props: {
    page: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      ranking: null,
      weekly: null,
      history: null,
    };
  },
  computed: {
    isRankedCur() {
      if (this.ranking === null) return null;
      return _.map(this.ranking.cur.ranking, v => v.user_id).includes(this.ranking.cur.myinfo.user_id);
    },
    isRankedPrev() {
      if (this.ranking === null) return null;
      return _.map(this.ranking.prev.ranking, v => v.user_id).includes(this.ranking.prev.myinfo.user_id);
    },
    isRankedTotal() {
      if (this.ranking === null) return null;
      return _.map(this.ranking.total.ranking, v => v.user_id).includes(this.ranking.total.myinfo.user_id);
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
      axios.get(`/login_log/${this.page}`).then((res) => {
        this.$set(this, this.page, res.data);
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

.bar {
  display: inline-block;
  &.mylog {
    background-color: #ff6600;
  }
  &.total {
    background-color: teal;
  }
  &.total-max {
    background-color: purple;
  }
}
</style>
