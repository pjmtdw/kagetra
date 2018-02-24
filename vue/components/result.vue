<template>
  <div id="container" class="mx-auto">
    <div class="container my-2">
      <div class="row">
        <nav id="nav-result-pages" class="col-12 col-md-8">
          <ul class="pagination justify-content-center justify-content-md-start">
            <li class="page-item active"><span class="page-link p-1 p-sm-2">大会結果</span></li>
            <li class="page-item"><router-link class="page-link p-1 p-sm-2" to="/list">大会一覧</router-link></li>
            <li class="page-item"><router-link class="page-link p-1 p-sm-2" to="/list">個人記録</router-link></li>
            <li class="page-item"><router-link class="page-link p-1 p-sm-2" to="/list">昇級履歴</router-link></li>
            <li class="page-item"><router-link class="page-link p-1 p-sm-2" to="/list">ランキング</router-link></li>
          </ul>
        </nav>
        <div class="col-12 col-md-4 p-0 mt-2 mt-md-0">
          <player-search id="top-plsearch" class="justify-content-md-start" placeholder="選手名検索" />
        </div>
      </div>
    </div>
    <div v-if="recent_list" class="container">
      <div class="row">
        <nav id="recent_list" class="col-12 col-md-8 nav nav-pills flex-row flex-wrap justify-content-center justify-content-md-start" role="tablist">
          <router-link v-for="ct in recent_list" :to="`/${ct.id}`" :key="ct.id"
                       class="nav-link p-1 p-sm-2" :class="{active: (ct.id == contest_id) || (contest_id == -1 && ct.most_recent)}" role="tab">
            {{ ct.name }}
          </router-link>
        </nav>
        <div class="col-12 col-md-4">
          <div class="btn-group">
            <button type="button" class="btn btn-info" data-toggle="modal" data-target="#past_result" @click="fetch_past_info">過去の結果</button>
            <button type="button" class="btn btn-info dropdown-toggle dropdown-toggle-split" data-toggle="dropdown"
                    aria-haspopup="true" aria-expanded="false"/>
            <div class="dropdown-menu dropdown-menu-right">
              <router-link v-for="g in group" :key="g.id" :to="`/${g.id}`" class="dropdown-item">{{ g.date }} {{ g.name }}</router-link>
            </div>
          </div>
          <button type="button" class="btn btn-success mx-1">大会追加</button>
          <a class="align-self-center" :href="`result/excel/${id}/${date}_${encodeURI(name)}.xls`">印刷用</a>
          <div id="past_result" class="modal fade" tabindex="-1" role="dialog" aria-hidden="true">
            <div class="modal-dialog modal-lg" role="document">
              <div class="modal-content">
                <div class="modal-header">
                  <h5 class="modal-title">{{ past_name }}</h5>
                  <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                    <span aria-hidden="true">&times;</span>
                  </button>
                </div>
                <div class="modal-body">
                  <div class="card" v-if="past_description != null">
                    <h6 class="card-header d-flex justify-content-between align-items-center">
                      大会情報<button class="btn btn-success">編集</button>
                    </h6>
                    <div class="card-body pre bg-light">{{ past_description }}</div>
                  </div>
                  <hr v-if="past_description != null">
                  <div>
                    <nav v-if="past_pages > 1" class="pl-2">
                      <ul class="pagination">
                        <li v-for="p in past_pages" :key="p" class="page-item" :class="{'active': p == past_cur_page}">
                          <a class="page-link" href="#" @click.prevent="load_past_list">
                            {{ p }}
                          </a>
                        </li>
                      </ul>
                    </nav>
                    <div v-for="result in past_list" class="comment py-1">
                      {{ result }}
                    </div>
                  </div>
                </div>
                <div class="modal-footer">
                  <button type="button" class="btn btn-secondary" data-dismiss="modal">閉じる</button>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    <div v-if="name" class="mt-4 mb-3">
      <span class="h5 mx-1" :class="{'unofficial': !official}">{{ official ? '♠' : '♣' }}</span>
      <span class="h5"><strong>{{ name }}</strong></span>
      <span class="h6 date">@{{ date }}</span>
    </div>
    <nav v-if="name" class="mt-2">
      <div class="nav nav-tabs" id="nav-tab" role="tablist">
        <a class="nav-item nav-link border active" id="nav-result-tab" data-toggle="tab" href="#nav-result" role="tab" aria-controls="nav-result" aria-selected="true">結果</a>
        <a class="nav-item nav-link border" id="nav-info-tab" data-toggle="tab" href="#nav-info" role="tab" aria-controls="nav-info" aria-selected="false">情報</a>
        <a class="nav-item nav-link border" id="nav-comment-tab" data-toggle="tab" href="#nav-comment" role="tab" aria-controls="nav-comment" aria-selected="false">コメント({{ comment_count }})</a>
      </div>
    </nav>
    <div v-if="name" class="tab-content">
      <div class="tab-pane border border-top-0 bg-white rounded-bottom fade show active" id="nav-result" role="tabpanel" aria-labelledby="nav-result-tab">
        <div class="d-flex justify-content-between">
          <div>
            <button class="btn btn-success m-2">編集開始</button>
            <button class="btn btn-success m-2">出場者編集</button>
          </div>
          <div>
            <button class="btn btn-info m-2" @click="fetch(contest_id)">更新</button>
          </div>
        </div>
        <div v-for="res in contest_results" :key="res.class_id" class="mb-5">
          <span class="badge badge-pill badge-primary">{{ contest_classes[res.class_id].class_name }}</span>
          <span v-if="contest_classes[res.class_id].num_person" class="badge badge-secondary">{{ contest_classes[res.class_id].num_person }}人</span>
          <div class="d-flex flex-row">
            <table class="table-name">
              <thead>
                <tr>
                  <th scope="col" class="text-center">名前</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="user in res.user_results" :key="user.cuid" :class="`row-${user.cuid}`">
                  <td class="text-center">
                    <div>{{ user.user_name }}</div>
                    <div v-if="user.prize" class="prize">
                      <span v-if="user.prize.prize">{{ `${user.prize.prize}` }}</span>
                      <span v-if="user.prize.point > 0 && user.prize.point_local > 0"><br>{{ `[${user.prize.point}pt, ${user.prize.point_local}kpt]` }}</span>
                      <span v-else-if="user.prize.point > 0">{{ `[${user.prize.point}pt]` }}</span>
                      <span v-else-if="user.prize.point_local > 0">{{ `[${user.prize.point_local}kpt]` }}</span>
                    </div>
                  </td>
                </tr>
              </tbody>
            </table>
            <div class="table-responsive">
              <table class="table-result">
                <thead>
                  <tr>
                    <th v-for="(round, i) in res.rounds" :key="i" scope="col" class="text-center">{{ round.name === null ? `${i+1}回戦` : round.name }}</th>
                  </tr>
                </thead>
                <tbody>
                  <tr v-for="user in res.user_results" :key="user.cuid" :class="`row-${user.cuid}`">
                    <td v-for="game in user.game_results" class="text-center" :class="`result-${game.result}`">
                      <div v-if="game.result === 'break'" />
                      <div v-else-if="game.result === 'default_win'">不戦</div>
                      <template v-else-if="game.result === 'win'">
                        <div>○ {{ game.score_str }} {{ game.opponent_name }}</div>
                        <div>({{ game.opponent_belongs }})</div>
                      </template>
                      <template v-else-if="game.result === 'lose'">
                        <div>● {{ game.score_str }} {{ game.opponent_name }}</div>
                        <div>({{ game.opponent_belongs }})</div>
                      </template>
                      <template v-else-if="game.result === 'now'">
                        <div>対戦中 {{ game.opponent_name }}</div>
                        <div>({{ game.opponent_belongs }})</div>
                      </template>
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>
      <div class="tab-pane border border-top-0 bg-white rounded-bottom fade" id="nav-info" role="tabpanel" aria-labelledby="nav-info-tab">
        <div class="container">
          <div class="row">
            <div class="col-12 col-md-8">
              <div class="card mt-3">
                <h6 class="card-header"><strong>大会/行事名</strong></h6>
                <div class="card-body">
                  {{ name }}
                  <span v-if="formal_name">({{ formal_name }})</span>
                </div>
              </div>
            </div>
            <div class="col-12 col-md-4">
              <div class="card mt-3">
                <h6 class="card-header"><strong>種別</strong></h6>
                <div class="card-body">
                  <span v-if="official">公認</span><span v-else>非公認</span>
                  <span v-if="team_size === 1">個人戦</span><span v-else-if="team_size === 3">三人団体戦</span><span v-else-if="team_size === 5">五人団体戦</span>
                </div>
              </div>
            </div>
          </div>
          <div class="row">
            <div class="col-12 col-md-8">
              <div class="card mt-3">
                <h6 class="card-header"><strong>場所</strong></h6>
                <div class="card-body">
                  {{ place }}
                </div>
              </div>
            </div>
            <div class="col-12 col-md-4">
              <div class="card mt-3">
                <h6 class="card-header"><strong>日時</strong></h6>
                <div class="card-body">
                  <span>{{ date }}</span>
                  <span v-if="start_at">{{ start_at }} 〜</span>
                  <span v-if="end_at">{{ end_at }}</span>
                </div>
              </div>
            </div>
          </div>
          <div class="row">
            <div class="col">
              <div class="card mt-3">
                <h6 class="card-header"><strong>備考</strong></h6>
                <div class="card-body pre">{{ description }}</div>
              </div>
            </div>
          </div>
          <div v-if="attached" class="row">
            <div class="col">
              <div class="card my-3">
                <h6 class="card-header"><strong>添付ファイル</strong></h6>
                <div class="card-body">
                  <a v-for="at in attached" :href="`/static/event/attached/${at.id}/${encodeURI(at.orig_name)}`" class="d-block">{{ at.orig_name }}</a>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
      <div class="tab-pane border border-top-0 bg-white rounded-bottom fade" id="nav-comment" role="tabpanel" aria-labelledby="nav-comment-tab">
        <button class="btn btn-success m-2" @click="post_new_comment">
          書き込む
        </button>
        <span class="m-2">
          <strong>{{ thread_name }}</strong>
        </span>
        <nav v-if="pages > 1" class="pl-2">
          <ul class="pagination">
            <li v-for="p in pages" :key="p" class="page-item" :class="{'active': p == cur_page}">
              <a class="page-link" href="#" @click.prevent="load_comment">
                {{ p }}
              </a>
            </li>
          </ul>
        </nav>
        <div v-for="comment in list" class="comment py-1">
          <div class="pl-1">
            <span>{{ comment.user_name }}</span>
            <span class="date">@{{ comment.date }}</span>
          </div>
          <div class="pt-2 pl-3">
            {{ comment.body }}
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
<script>
export default {
  props: {
    contest_id: {
      type: String,
      default: '-1',
    },
  },
  data() {
    return {
      // result
      id: 0,
      official: null,
      name: '',
      date: '',
      team_size: 1,
      recent_list: [],
      contest_classes: [],
      contest_results: [],
      event_group_id: -1,
      group: [],
      album_groups: [],
      // detail
      formal_name: '',
      start_at: '',
      end_at: '',
      place: '',
      description: [],
      attached: [],
      editable: false,
      // comment
      comment_count: 0,
      cur_page: 1,
      pages: 1,
      thread_name: '',
      list: [],
      // has_new_comment: false,
      // past info
      past_cur_page: 1,
      past_description: '',
      past_list: [],
      past_name: '',
      past_pages: 1,
    };
  },
  watch: {
    contest_id(val) {
      this.fetch(val);
      $('#nav-result-tab').tab('show');
    },
  },
  created() {
    this.fetch().then(() => {
      this.fetch_detail();
    });
  },
  mounted() {
    $('#nav-result-tab').on('shown.bs.tab', this.set_cell_height);
  },
  updated() {
    this.set_cell_height();
  },
  methods: {
    fetch() {
      const baseUrl = '/api/result/contest';
      const url = this.contest_id === '-1' ? `${baseUrl}/latest` : `${baseUrl}/${this.contest_id}`;
      return axios.get(url).then((res) => {
        _.forEach(res.data, (v, key) => {
          this[key] = v;
        });
        this.fetch_comment();
      }).catch(() => {
        $.notify('danger', '大会の取得に失敗しました');
      });
    },
    fetch_detail() {
      const url = `/api/event/item/${this.id}?detail=true&no_participant=true`;
      axios.get(url).then((res) => {
        _.forEach(['formal_name', 'start_at', 'end_at', 'place', 'description', 'attached', 'editable'], (v) => {
          this[v] = res.data[v];
        });
      }).catch(() => {
        $.notify('danger', '大会情報の取得に失敗しました');
      });
    },
    fetch_comment() {
      const contestId = this.id;
      const page = this.cur_page;
      const baseUrl = `/api/event/comment/list/${contestId}`;
      const url = page === 1 ? baseUrl : `${baseUrl}?page=${page}`;
      axios.get(url).then((res) => {
        _.forEach(res.data, (v, key) => {
          this[key] = v;
        });
      });
    },
    post_new_comment() {
    },
    load_comment(e) {
      this.cur_page = Number($(e.target).html());
      this.fetch_comment();
    },
    fetch_past_info() {
      const page = this.past_cur_page;
      const baseUrl = `/api/result/group/${this.event_group_id}`;
      const url = page === 1 ? baseUrl : `${baseUrl}?page=${page}`;
      axios.get(url).then((res) => {
        _.forEach(res.data, (v, key) => {
          this[`past_${key}`] = v;
        });
      }).catch(() => {
        $.notify('danger', '過去の結果の取得に失敗しました');
      });
    },
    load_past_list(e) {
      this.past_cur_page = Number($(e.target).html());
      this.fetch_past_info();
    },
    set_cell_height() {
      // セルの高さを揃える
      const rows = new Set();
      $('.table-result tbody tr').each((index, elem) => {
        rows.add($(elem).attr('class'));
      });
      rows.forEach((v) => {
        let maxH = 0;
        $(`.${v}`).each((index, elem) => {
          maxH = _.max([maxH, $(elem).height()]);
        });
        $(`.${v}`).css('height', maxH);
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

#nav-result-tab, #nav-info-tab, #nav-comment-tab {
  &:not(.active) {
    background-color: #f8f9fa;
  }
  &.active {
    border-bottom: 0!important;
  }
}

// #recent_list a {
//   font-size: 0.8rem;
//   @media screen and (max-width: 767.98px) {
//     font-size: 0.7rem;
//   }
// }

.unofficial {
  color: green;
}
.date {
  color: brown;
}
.comment {
  border-top: gray dotted 1px;
}
.dropdown-menu {
  max-height: 50vh;
  overflow-y: auto;
}
</style>
