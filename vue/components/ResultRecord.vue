<template>
  <main id="container" class="mx-auto">
    <!-- nav, 選手名検索 -->
    <div class="container my-2">
      <div class="row">
        <nav id="nav-result-pages" class="col-12 col-md-8">
          <ul class="pagination justify-content-center justify-content-md-start">
            <li class="page-item"><router-link class="page-link p-1 p-sm-2" to="/">大会結果</router-link></li>
            <li class="page-item"><router-link class="page-link p-1 p-sm-2" to="/list">大会一覧</router-link></li>
            <li class="page-item active"><span class="page-link p-1 p-sm-2">個人記録</span></li>
            <li class="page-item"><router-link class="page-link p-1 p-sm-2" to="/promotion">昇級履歴</router-link></li>
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
    <!-- 名前 -->
    <h5 class="font-weight-bold">{{ name === 'myself' ? user_name : name }}</h5>
    <!-- サマリー -->
    <table class="summary table table-sm bg-white border rounded">
      <thead v-if="sum !== null" class="thead-light">
        <tr>
          <th class="cursor-pointer" @click="hidden = !hidden">
            <span v-if="hidden" class="d-inline-block" style="transform: rotate(90deg);">▲</span>
            <span v-else class="d-inline-block">▼</span>
            計&ensp;&emsp;
          </th>
          <th>{{ sum.count }}大会</th>
          <th>{{ sum.win }}勝</th>
          <th>{{ sum.lose }}敗</th>
          <th>({{ sum.win_percent }}%)</th>
          <th>[{{ sum.point }}pt]</th>
          <th>[{{ sum.point_local }}kpt]</th>
        </tr>
      </thead>
      <tbody v-show="!hidden">
        <template v-for="ag in aggr">
          <tr :key="`y${ag.year}`">
            <td>{{ ag.year }}年</td>
            <td>{{ ag.count }}大会</td>
            <td>{{ ag.win }}勝</td>
            <td>{{ ag.lose }}敗</td>
            <td>({{ ag.win_percent }}%)</td>
            <td>[{{ ag.point }}pt]</td>
            <td>[{{ ag.point_local }}kpt]</td>
          </tr>
          <tr v-for="(pc, i) in ag.prize_contests" :key="pc">
            <td class="border-0" :class="{ 'border-top-dotted': i === 0 }" colspan="7">
              <span>{{ formatDate(events[pc].date) }}</span>
              <router-link :to="`/${pc}`" class="card-link">{{ events[pc].name }}</router-link>
              <span :class="{ 'text-success': prizes[pc].promotion === 'rank_up' }">
                {{ class_info[pc].class_name }}
                {{ prizes[pc].prize }}
                {{ prizes[pc].point > 0 ? `[${prizes[pc].point}pt, ${prizes[pc].point_local}kpt]` :
                (prizes[pc].point_local > 0 ? `[${prizes[pc].point_local}kpt]` : '') }}
              </span>
            </td>
          </tr>
        </template>
      </tbody>
    </table>
    <!-- ページネーション -->
    <ul class="pagination my-2 justify-content-center">
      <li v-for="i in pages" class="page-item" :class="{ active: page == i }" :key="i" data-toggle="tooltip" :title="page_infos[i-1]">
        <router-link class="page-link" :to="{ query: { page: i } }">{{ i }}</router-link>
      </li>
    </ul>
    <!-- 結果 -->
    <div class="d-flex flex-row">
      <table class="table-result">
        <tbody>
          <tr v-for="eventid in event_details" :key="eventid" :class="`row-${eventid}`">
            <td class="text-center" :class="{ opponent: events[eventid].is_op }">
              <span v-if="events[eventid].official">&spades;</span>
              <span v-else class="text-success">&clubs;</span>
              <router-link tag="span" class="cursor-pointer" :to="`/${eventid}`">{{ events[eventid].name }}</router-link>
              <div>@{{ events[eventid].date }}</div>
              <div>
                {{ class_info[eventid].class_name }}
                {{ my_belongs[eventid] }}
              </div>
              <div v-if="prizes[eventid]" class="prize">
                <span v-if="prizes[eventid].prize">{{ `${prizes[eventid].prize}` }}</span>
                <span v-if="prizes[eventid].point > 0 && prizes[eventid].point_local > 0">{{ `[${prizes[eventid].point}pt, ${prizes[eventid].point_local}kpt]` }}</span>
                <span v-else-if="prizes[eventid].point > 0">{{ `[${prizes[eventid].point}pt]` }}</span>
                <span v-else-if="prizes[eventid].point_local > 0">{{ `[${prizes[eventid].point_local}kpt]` }}</span>
              </div>
            </td>
            <td v-for="(game, i) in games[eventid]" class="text-center" :class="`result-${game.result}`">
              <div v-if="game.result === 'break'"/>
              <div v-else-if="game.result === 'default_win'">
                <div class="text-muted">- {{ class_info[eventid].round_name[i] || `${i}回戦` }} -</div>
                不戦
              </div>
              <template v-else>
                <div class="text-muted">- {{ class_info[eventid].round_name[i] || `${i}回戦` }} -</div>
                <div>
                  {{ result_str[game.result] }} {{ game.score_str }}
                  <router-link tag="span" class="cursor-pointer" :to="`/record/${game.opponent_name}`">{{ game.opponent_name }}</router-link>
                </div>
                <div>
                  <span v-if="game.opponent_belongs">({{ game.opponent_belongs }})</span>
                  <span v-if="game.comment" class="info-icon" data-toggle="tooltip" data-placement="bottom" :title="game.comment"/>
                </div>
              </template>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    <!-- ページネーション -->
    <ul class="pagination my-2 justify-content-center">
      <li v-for="i in pages" class="page-item" :class="{ active: page == i }" :key="i" data-toggle="tooltip" :title="page_infos[i-1]">
        <router-link class="page-link" :to="{ query: { page: i } }">{{ i }}</router-link>
      </li>
    </ul>
  </main>
</template>
<script>
import PlayerSearch from './subcomponents/PlayerSearch.vue';

/* global g_user_name */
export default {
  components: {
    PlayerSearch,
  },
  props: {
    name: {
      type: String,
      required: true,
    },
    page: {
      type: Number,
      required: true,
    },
  },
  data() {
    return {
      user_name: g_user_name,
      // サマリー
      aggr: null,
      events: null,
      class_info: null,
      prizes: null,
      hidden: true,
      // pagination
      pages: 0,
      page_infos: [],
      // 結果
      result_str: $.util.result_str,
      event_details: null,
      my_belongs: null,
      games: null,
    };
  },
  computed: {
    sum() {
      if (this.aggr === null) return null;
      let count = 0;
      let win = 0;
      let lose = 0;
      let point = 0;
      let kpt = 0;
      _.each(this.aggr, (ag) => {
        count += ag.count;
        win += ag.win;
        lose += ag.lose;
        point += ag.point;
        kpt += ag.point_local;
      });
      return {
        count,
        win,
        lose,
        win_percent: _.round(win / (win + lose) * 100, 1),
        point,
        point_local: kpt,
      };
    },
    displayPages() {
      if (this.pages >= 10) {
        return _.range(_.max(1, this.page - 4), _.min(this.pages, this.page + 4));
      }
      return _.range(1, this.pages + 1);
    },
  },
  watch: {
    name() {
      this.fetch();
    },
    page() {
      this.fetch();
    },
  },
  created() {
    this.fetch();
  },
  updated() {
    $('[data-toggle="tooltip"]').tooltip();
  },
  methods: {
    fetch() {
      const data = {
        name: this.name,
        no_aggr: false,
        page: this.page,
        span: 'full',
      };
      axios.post('/result_misc/record', data).then((res) => {
        const keys = ['aggr', 'events', 'event_details', 'class_info', 'prizes', 'my_belongs', 'games', 'pages', 'page_infos'];
        _.each(keys, (key) => {
          this[key] = res.data[key];
        });
      });
    },
    // Y-m-d => m月d日
    formatDate(date) {
      const d = new Date(date);
      return `${d.getMonth() + 1}月${d.getDate()}日`;
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
