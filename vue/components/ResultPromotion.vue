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
    <!-- nav -->
    <nav class="nav nav-pills mb-3">
      <router-link to="/promotion" class="nav-item nav-link px-2 py-1" exact-active-class="active">最近</router-link>
      <router-link to="/promotion/ranking" class="nav-item nav-link px-2 py-1" active-class="active">ランキング</router-link>
    </nav>
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
    <!-- ランキング -->
    <div v-else>
      <form id="promotion-ranking-form" class="form-inline mb-3">
        <select name="from" class="custom-select" @change="fetch">
          <option value="debut">かるたを始めて</option>
          <option value="prom_c">C級に昇級して</option>
          <option value="prom_b">B級に昇級して</option>
          <option value="prom_a">A級に昇級して</option>
        </select>
        <span class="mx-1">から</span>
        <select name="to" class="custom-select" @change="fetch">
          <option value="prom_c">C級に昇級</option>
          <option value="prom_b">B級に昇級</option>
          <option value="prom_a" selected>A級に昇級</option>
          <option value="a_champ">A級で優勝</option>
        </select>
        <span class="mx-1">するまで</span>
        <select name="mode" class="custom-select" @change="fetch">
          <option value="days">の日数のランキングを</option>
          <option value="contests">の大会数のランキングを</option>
          <option value="list">を日付順に</option>
        </select>
        <span class="mx-1">表示</span>
        <span class="info-icon" data-toggle="tooltip" data-placement="bottom" title="「かるたを始めて」というのは大会初出場日から過去に遡った最初の4月1日からという意味です．"/>
      </form>
      <div v-if="median" class="my-1">中央値: {{ median }}</div>
      <table class="table table-sm table-striped bg-white border px-2">
        <tbody>
          <tr v-for="(x, i) in ranking">
            <template v-if="display === 'ranking'">
              <td>{{ i + 1 }}</td>
              <td>
                <router-link :to="`/record/${x.user_name}`" class="card-link">{{ x.user_name }}</router-link>
              </td>
              <td>{{ x.days_str }} ({{ x.contests }}大会)</td>
              <td>
                {{ x.start.event_date }} ~ {{ x.end.event_date }}
                (<router-link :to="`/${x.end.event_id}`" class="card-link">{{ x.end.event_name }}</router-link> {{ x.end.prize }})
              </td>
            </template>
            <template v-else-if="display === 'a_champ'">
              <td>{{ i + 1 }}</td>
              <td>
                <router-link :to="`/record/${x.user_name}`" class="card-link">{{ x.user_name }}</router-link>
              </td>
              <td>
                {{ x.event_date }}
                <router-link :to="`/${x.event_id}`" class="card-link">{{ x.event_name }}</router-link>
                <span>{{ x.a_champ_count === 1 ? '初優勝' : `${x.a_champ_count}回目` }}</span>
                <span v-if="x.nth_champ">{{ x.nth_champ }}人目</span>
              </td>
            </template>
          </tr>
        </tbody>
      </table>
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
      // recent
      attrs: null,
      list: [],
      // ranking
      display: null,
      ranking: [],
      median: null,
    };
  },
  watch: {
    recent() {
      this.$nextTick(this.fetch);
    },
  },
  mounted() {
    this.fetch();
    $('[data-toggle="tooltip"]').tooltip();
  },
  methods: {
    fetch() {
      if (this.recent) {
        axios.get('/result_promotion/recent').then((res) => {
          this.attrs = res.data.attrs;
          this.list = _.map(res.data.list, (x) => {
            x.attrs = [];
            _.each(this.attrs, (a) => {
              x.attrs.push(_.clone(_.find(a[1], v => _.includes(x.attr_values, v[1]))));
            });
            return x;
          });
        });
      } else {
        const data = $('#promotion-ranking-form').serializeObject();
        axios.get('/result_promotion/ranking', { params: data }).then((res) => {
          this.ranking = res.data.list;
          this.display = res.data.display;
          this.median = res.data.median;
        });
      }
    },
    toggleEditAttr(event) {
      $(this.$refs[event.target.getAttribute('data-target')]).toggleClass('show');
    },
    changeAttr(x) {
      const data = { values: _.map(x.attrs, v => v[1]) };
      axios.post(`/user/change_attr/${x.event.id}/${x.user_id}`, data).then(() => {
        this.$_notify('変更しました');
      }).catch(() => {
        this.$_notify('danger', '変更に失敗しました');
      });
    },
  },
};
</script>
<style lang="scss" scoped>
@import '../sass/result.scss';

#container {
  width: 100%;
  max-width: 860px;
}
</style>
