<template>
  <main id="container" class="mx-auto">
    <!-- nav, 選手名検索 -->
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
        <div class="col-12 col-md-4 mt-2 mt-md-0">
          <PlayerSearch class="justify-content-md-start" placeholder="選手名検索" :complete="false"/>
        </div>
      </div>
    </div>
    <!-- 前後の大会, 編集ボタン等 -->
    <div v-show="loaded" class="container">
      <div class="row">
        <nav v-if="recent_list" id="recent_list"
             class="col-12 col-md-8 nav nav-pills flex-row flex-wrap justify-content-center justify-content-md-start mb-1" role="tablist">
          <router-link v-for="ct in recent_list" :key="ct.id" :to="ct.id.toString()"
                       class="nav-link p-1 p-sm-2" :class="{active: (ct.id == contestId) || (contestId === null && ct.most_recent)}" role="tab">
            {{ ct.name }}
          </router-link>
        </nav>
        <div v-show="editable !== null" class="col-12 col-md-4 mb-1">
          <div class="btn-group mb-1" role="group">
            <!-- <button v-if="editable" type="button" class="btn btn-success" data-toggle="modal" data-target="#add_event_dialog">追加</button> -->
            <button v-if="editable" type="button" class="btn btn-success" data-toggle="modal" data-target="#edit_event_dialog">編集</button>
            <a :href="`result/excel/${id}/${date}_${encodeURI(name)}.xls`" class="btn btn-secondary">保存</a>
          </div>
        </div>
      </div>
    </div>
    <!-- 大会名, 日時, 過去の結果 -->
    <div v-show="loaded" class="mt-4 mb-3">
      <span class="h5 mx-1" :class="{'unofficial': !official}">{{ official ? '&spades;' : '&clubs;' }}</span>
      <span class="h5"><strong>{{ name }}</strong></span>
      <span class="h6 date">@{{ date }}</span>
      <div v-if="event_group_id" class="btn-group mb-1">
        <button type="button" class="btn btn-info py-1" data-toggle="modal" data-target="#past_result" @click="fetchPastInfo">過去の結果</button>
        <button type="button" class="btn btn-info py-1 dropdown-toggle dropdown-toggle-split" data-toggle="dropdown"
                aria-haspopup="true" aria-expanded="false"/>
        <div class="dropdown-menu dropdown-menu-right">
          <router-link v-for="g in group" :key="g.id" :to="`/${g.id}`" class="dropdown-item">{{ g.date }} {{ g.name }}</router-link>
        </div>
      </div>
      <div v-if="event_group_id" id="past_result" class="modal fade" tabindex="-1" role="dialog" aria-hidden="true">
        <div class="modal-dialog modal-lg" role="document">
          <div class="modal-content">
            <div class="modal-header">
              <h5 class="modal-title">{{ past_name }}</h5>
              <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                <span aria-hidden="true">&times;</span>
              </button>
            </div>
            <div class="modal-body">
              <div v-if="past_description != null" class="card">
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
                      <a class="page-link" href="#" @click.prevent="loadPastList">
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
    <!-- タブ -->
    <nav v-show="loaded" class="mt-2">
      <div class="nav nav-tabs" id="nav-tab" role="tablist">
        <a class="nav-item nav-link border active" id="nav-result-tab" data-toggle="tab" href="#nav-result" role="tab" aria-controls="nav-result" aria-selected="true">
          結果
        </a>
        <a class="nav-item nav-link border" id="nav-info-tab" data-toggle="tab" href="#nav-info" role="tab" aria-controls="nav-info" aria-selected="false">
          情報
        </a>
        <a class="nav-item nav-link border" id="nav-comment-tab" data-toggle="tab" href="#nav-comment" role="tab" aria-controls="nav-comment" aria-selected="false">
          コメント
          <span v-if="comment_count">({{ `${comment_count}${has_new_comment ? ' new' : ''}` }})</span>
        </a>
      </div>
    </nav>
    <!-- タブの中 -->
    <div v-show="loaded" class="tab-content">
      <!-- 結果 -->
      <div class="tab-pane border border-top-0 bg-white rounded-bottom show active" id="nav-result" role="tabpanel" aria-labelledby="nav-result-tab">
        <div class="d-flex justify-content-between">
          <div class="ml-2 my-2">
            <button class="btn btn-success mx-1" data-toggle="button" aria-pressed="false">結果編集</button>
            <button v-if="!isTeamGame" class="btn btn-success mx-1" data-toggle="modal" data-target="#edit_num_person_dialog">人数編集</button>
            <button class="btn btn-success mx-1" data-toggle="modal" data-target="#edit_players_dialog">出場者編集</button>
          </div>
          <div>
            <button class="btn btn-info m-2" @click="update">更新</button>
          </div>
        </div>
        <div v-for="(res, i) in contest_results" :key="isTeamGame ? res.team_id : res.class_id" class="mb-5">
          <!-- 団体戦でclass_name(東大, お茶大など)を表示するか -->
          <template v-if="!(i > 0 && res.class_id === contest_results[i-1].class_id && contest_results[i-1].rounds.length)">
            <span class="badge badge-pill badge-class-name">{{ contest_classes[res.class_id].class_name }}</span>
            <span v-if="contest_classes[res.class_id].num_person" class="badge badge-secondary">{{ contest_classes[res.class_id].num_person }}人</span>
          </template>
          <div class="d-flex flex-row mt-1">
            <table class="table-name">
              <thead>
                <tr :class="isTeamGame ? `row-team-${res.team_id}` : `row-cls-${res.class_id}`">
                  <th v-if="!isTeamGame" scope="col" class="text-center">名前</th>
                  <th v-else scope="col" class="text-center">
                    <div>{{ res.header_left.team_name }}</div>
                    <div class="team-prize">{{ res.header_left.team_prize }}</div>
                  </th>
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
                  <tr :class="isTeamGame ? `row-team-${res.team_id}` : `row-cls-${res.class_id}`">
                    <th v-for="(round, i) in res.rounds" scope="col" class="text-center">
                      <div v-if="!isTeamGame">{{ round.name === null ? `${i+1}回戦` : round.name }}</div>
                      <div v-else>{{ round.op_team_name }}</div>
                    </th>
                  </tr>
                </thead>
                <tbody>
                  <tr v-for="user in res.user_results" :key="user.cuid" :class="`row-${user.cuid}`">
                    <td v-for="game in user.game_results" class="text-center" :class="`result-${game.result}`">
                      <div v-if="game.result === 'break'"/>
                      <div v-else-if="game.result === 'default_win'">不戦</div>
                      <template v-else>
                        <div>{{ result_str[game.result] }} {{ game.score_str }} {{ game.opponent_name }}</div>
                        <div v-if="game.opponent_belongs">
                          ({{ game.opponent_belongs }})
                          <span v-if="game.comment" data-toggle="tooltip" data-placement="bottom" :title="game.comment">※</span>
                        </div>
                        <div v-else-if="game.opponent_order">
                          ({{ order_str[game.opponent_order] }})
                          <span v-if="game.comment" data-toggle="tooltip" data-placement="bottom" :title="game.comment">※</span>
                        </div>
                      </template>
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>
      <!-- 情報 -->
      <div class="tab-pane border border-top-0 bg-white rounded-bottom pb-3" id="nav-info" role="tabpanel" aria-labelledby="nav-info-tab">
        <div class="container">
          <div class="row">
            <div class="col-12 col-md-8">
              <div class="card mt-3">
                <div class="card-header d-flex align-items-center justify-content-between">
                  <h6 class="mb-0"><strong>大会/行事名</strong></h6>
                </div>
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
                  <span>({{ weekday }})</span>
                  <span v-html="time"/>
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
          <div class="row">
            <div class="col">
              <div class="card mt-3">
                <h6 class="card-header"><strong>添付ファイル</strong></h6>
                <div class="card-body">
                  <div v-for="f in attached" :key="f.id" class="mb-1">
                    <a :href="`/static/event/attached/${f.id}/${encodeURI(f.orig_name)}`" class="badge badge-light-shadow">
                      {{ f.orig_name }}
                    </a>
                    <p class="d-inline ml-2">{{ f.description }}</p>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
      <!-- コメント -->
      <div class="tab-pane border border-top-0 bg-white rounded-bottom pb-3" id="nav-comment" role="tabpanel" aria-labelledby="nav-comment-tab">
        <div class="d-flex justify-content-between align-items-center">
          <h5 class="m-2">
            <strong>{{ thread_name }}</strong>
          </h5>
          <button id="new-comment-toggle" class="btn btn-success m-2" data-toggle="collapse" href="#new-comment-form"
                  aria-expanded="false" aria-controls="new-comment-form" @click="toggleNewComment">
            書き込む
          </button>
        </div>
        <NewCommentForm id="new-comment-form" class="mx-3 mb-3 mt-2" url="/api/event/comment/item" :thread-id="id" @done="postDone"/>
        <nav v-if="pages > 1" class="pl-2">
          <ul class="pagination">
            <li v-for="p in pages" :key="p" class="page-item" :class="{'active': p == cur_page}">
              <a class="page-link" href="#" @click.prevent="loadComment">
                {{ p }}
              </a>
            </li>
          </ul>
        </nav>
        <CommentList :comments="list" url="/api/event/comment/item" item-class="px-2 py-1" @done="fetchComment"/>
      </div>
    </div>
    <!-- 大会追加dialog -->
    <!-- <ContestDialog id="add_event_dialog"/> -->
    <!-- 大会編集dialog -->
    <ContestDialog id="edit_event_dialog" :contest-id="id" @done="fetch"/>
    <!-- 人数編集dialog -->
    <div v-if="!isTeamGame" id="edit_num_person_dialog" class="modal fade" tabindex="-1" role="dialog" aria-hidden="true" @keydown.enter="saveNumPerson">
      <div class="modal-dialog modal-sm" role="document">
        <div class="modal-content">
          <div class="modal-header">
            <h5 class="modal-title">各級の出場人数</h5>
            <button type="button" class="close" data-dismiss="modal" aria-label="Close">
              <span aria-hidden="true">&times;</span>
            </button>
          </div>
          <div class="modal-body">
            <form @change="changed_num_person = true" @submit.prevent>
              <div v-for="(c, i) in contest_classes" class="form-group row">
                <label :for="`num_person_input${i}`" class="col-3 col-form-label">{{ c.class_name }}</label>
                <div class="col-9">
                  <input :id="`num_person_input${i}`" :value="c.num_person" type="number" class="form-control" :name="i">
                </div>
              </div>
            </form>
          </div>
          <div class="modal-footer">
            <button type="button" class="btn btn-success" @click="saveNumPerson">保存</button>
          </div>
        </div>
      </div>
    </div>
    <!-- 出場者編集dialog -->
    <div id="edit_players_dialog" class="modal fade" tabindex="-1" role="dialog" aria-hidden="true" @keydown.shift.enter="savePlayers">
      <div class="modal-dialog modal-lg" role="document">
        <div class="modal-content">
          <div class="modal-header">
            <h5 class="modal-title">出場者編集</h5>
            <button type="button" class="close" data-dismiss="modal" aria-label="Close">
              <span aria-hidden="true">&times;</span>
            </button>
          </div>
          <div v-if="players !== null" class="modal-body">
            <template v-if="!isTeamGame">
              <span>チェックした選手を操作</span>
              <div class="d-flex flex-row align-items-center">
                <div class="input-group d-inline-flex w-auto">
                  <select class="custom-select">
                    <option selected disabled value="-1">--級名--</option>
                    <option v-for="c in players.classes" :key="c[0]" :value="c[0]">{{ c[1] }}</option>
                  </select>
                  <div class="input-group-append">
                    <span class="input-group-text">に</span>
                    <button class="btn btn-outline-success" type="button" @click="movePlayers">移動</button>
                  </div>
                </div>
                <button class="btn btn-outline-danger ml-2" @click="deletePlayers">削除</button>
              </div>
              <div v-for="(c, i) in players.classes" :key="c[0]" class="card mt-4" :data-index="i">
                <div class="card-border-title d-flex">
                  <span class="badge badge-pill badge-class-name">
                    {{ c[1] }}
                  </span>
                  <button type="button" class="btn btn-secondary btn-sm py-0 ml-auto" @click="moveUpClass">&uarr;</button>
                  <button type="button" class="btn btn-secondary btn-sm py-0 ml-2" @click="moveDownClass">&darr;</button>
                  <button type="button" class="btn btn-success btn-sm py-0 ml-2" @click="addClass">+</button>
                  <button type="button" class="btn btn-danger btn-sm py-0 mx-2" @click="deleteClass">&times;</button>
                </div>
                <div class="card-body d-flex flex-wrap pt-1 pb-2">
                  <div v-for="u in players.user_classes[c[0]]" :key="u" class="form-check my-1 mr-3">
                    <label class="form-check-label">
                      <input type="checkbox" class="form-check-input mt-1" :data-id="u">
                      {{ players.users[u] }}
                    </label>
                  </div>
                  <span class="d-inline-flex align-items-center">
                    <button class="btn btn-outline-success btn-sm py-0" @click="showAddPlayer">+</button>
                  </span>
                  <span style="display: none;">
                    <PlayerSearch :inline="true" :clear-when-set="true" @complete="addPlayer"/>
                  </span>
                  <span class="input-group-append pb-1px" style="display: none;">
                    <button class="add btn btn-success btn-sm py-0" @click="addPlayer">追加</button>
                  </span>
                </div>
              </div>
            </template>
            <template v-else>
              <div/>
            </template>
          </div>
          <div class="modal-footer justify-content-between">
            <button type="button" class="btn btn-outline-danger" @click="resetPlayers">リセット</button>
            <button type="button" class="btn btn-success" @click="savePlayers">保存</button>
          </div>
        </div>
      </div>
    </div>
  </main>
</template>
<script>
import PlayerSearch from './subcomponents/PlayerSearch.vue';
import ContestDialog from './subcomponents/ContestDialog.vue';

export default {
  components: {
    PlayerSearch,
    ContestDialog,
  },
  props: {
    contestId: {
      type: String,
      default: null,
    },
  },
  data() {
    return {
      loaded: false,  // 表示タイミング調整
      result_str: $.util.result_str,
      order_str: $.util.order_str,
      comment_body: null,
      editing: false,
      // result
      id: null,
      official: null,
      name: null,
      date: null,
      team_size: 1,
      recent_list: null,
      contest_classes: null,
      contest_results: null,
      event_group_id: null,
      group: null,
      album_groups: null,
      // detail
      formal_name: null,
      start_at: null,
      end_at: null,
      place: null,
      description: null,
      attached: null,
      editable: null, // 表示タイミング調整のためfalseではなくnull
      // comment
      comment_count: null,
      cur_page: 1,
      pages: 1,
      thread_name: null,
      list: null,
      has_new_comment: false,
      // past info
      past_cur_page: 1,
      past_description: null,
      past_list: null,
      past_name: null,
      past_pages: 1,
      // edit
      changed_num_person: false,
      changed_players: false,
      players: null,
      new_class_count: 0,
      new_player_count: 0,
      new_team_count: 0,
    };
  },
  computed: {
    isTeamGame() {
      return this.team_size > 1;
    },
    rows() {
      return _.max([this.comment_body.split('\n').length, 4]);
    },
    weekday() {
      return $.util.getWeekDay(this.date);
    },
    time() {
      return $.util.timeRange(this.start_at, this.end_at);
    },
  },
  watch: {
    contestId() {
      this.fetch();
      $('#nav-result-tab').tab('show');
    },
  },
  created() {
    this.fetch();
  },
  mounted() {
    const $editNumPersonDialog = $('#edit_num_person_dialog');
    $editNumPersonDialog.on('hide.bs.modal', (e) => {
      if (!this.changed_num_person) return;
      e.preventDefault();
      this.$_confirm('本当に変更を破棄して閉じますか？').then(() => {
        this.changed_num_person = false;
        $editNumPersonDialog.modal('hide');
      }).catch(() => {
        $('body').addClass('modal-open');
      });
    });
    const $editPlayersDialog = $('#edit_players_dialog');
    $editPlayersDialog.on('show.bs.modal', () => {
      this.resetPlayers();
    });
    $editPlayersDialog.on('hide.bs.modal', (e) => {
      if (!this.changed_players) return;
      e.preventDefault();
      this.$_confirm('本当に変更を破棄して閉じますか？').then(() => {
        this.changed_players = false;
        $editPlayersDialog.modal('hide');
      }).catch(() => {
        $('body').addClass('modal-open');
      });
    });
  },
  updated() {
    this.setCellHeight();
    $('[data-toggle="tooltip"]').tooltip();
  },
  methods: {
    fetch() {
      const baseUrl = '/api/result/contest';
      const url = this.contestId === null ? `${baseUrl}/latest` : `${baseUrl}/${this.contestId}`;
      axios.get(url).then((res) => {
        _.forEach(res.data, (v, key) => {
          this[key] = v;
        });
        // 自身を削除
        this.group = this.group.filter(v => v.id !== this.id);
        this.fetchDetail();
        this.fetchComment();
        this.loaded = true;
      }).catch(() => {
        this.$_notify('danger', '大会結果の取得に失敗しました');
      });
    },
    fetchDetail() {
      const url = `/api/event/item/${this.id}?detail=true&no_participant=true`;
      axios.get(url).then((res) => {
        _.forEach(['formal_name', 'start_at', 'end_at', 'place', 'description', 'attached', 'editable'], (v) => {
          this[v] = res.data[v];
        });
      }).catch(() => {
        this.$_notify('danger', '大会情報の取得に失敗しました');
      });
    },
    fetchComment() {
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
    fetchPlayers() {
      axios.get(`/api/result/players/${this.id}`).then((res) => {
        this.players = res.data;
        this.players.deleted_classes = [];
        this.players.deleted_teams = [];
        this.players.deleted_users = [];
      }).catch(() => {
        this.$_notify('danger', '出場者情報の取得に失敗しました');
      });
    },
    loadComment(e) {
      this.cur_page = Number($(e.target).html());
      this.fetchComment();
    },
    toggleNewComment(e) {
      const $toggle = $(e.target);
      $toggle.toggleBtnText('書き込む', 'キャンセル');
      $toggle.toggleClass('btn-success');
      $toggle.toggleClass('btn-outline-success');
    },
    postDone() {
      $('#new-comment-toggle').click();
      this.fetchComment();
    },
    fetchPastInfo() {
      const page = this.past_cur_page;
      const baseUrl = `/api/result/group/${this.event_group_id}`;
      const url = page === 1 ? baseUrl : `${baseUrl}?page=${page}`;
      axios.get(url).then((res) => {
        _.forEach(res.data, (v, key) => {
          this[`past_${key}`] = v;
        });
      }).catch(() => {
        this.$_notify('danger', '過去の結果の取得に失敗しました');
      });
    },
    loadPastList(e) {
      this.past_cur_page = Number($(e.target).html());
      this.fetchPastInfo();
    },
    saveNumPerson() {
      const $dialog = $('#edit_num_person_dialog');
      const $form = $dialog.find('form');
      const onSave = () => {
        $form.removeClass('was-validated');
        this.$_notify('保存しました');
        this.changed_num_person = false;
        $dialog.modal('hide');
        this.fetch();
      };
      if (!$form.check()) {
        this.$_notify('warning', '不正な値です');
        return;
      }
      let data = {};
      data = $form.serializeObject();
      data = _.map(data, (v, k) => ({
        class_id: k,
        num_person: v === '' ? null : Number(v),
      }));
      // 更新箇所のみ送信
      data = _.filter(data, v => this.contest_classes[v.class_id].num_person !== v.num_person);
      if (data.length === 0) {
        onSave();
        return;
      }
      axios.post('/api/result/num_person', { data }).then(onSave).catch(() => {
        this.$_notify('danger', '保存に失敗しました');
      });
    },
    addClass(e) {
      this.$_inputDialog('級名を入力してください').then((res) => {
        const index = Number($(e.target).parents('.card').attr('data-index'));
        this.players.classes.splice(index + 1, 0, [`new_${this.new_class_count}`, res]);
        this.new_class_count += 1;
        this.changed_players = true;
      }).always(() => {
        $('body').addClass('modal-open');
      });
    },
    moveUpClass(e) {
      const index = Number($(e.target).parents('.card').attr('data-index'));
      if (index === 0) {
        this.$_notify('warning', '移動できません');
        return;
      }
      const target = this.players.classes.splice(index, 1)[0];
      this.players.classes.splice(index - 1, 0, target);
      this.changed_players = true;
    },
    moveDownClass(e) {
      const index = Number($(e.target).parents('.card').attr('data-index'));
      if (index === this.players.classes.length - 1) {
        this.$_notify('warning', '移動できません');
        return;
      }
      const target = this.players.classes.splice(index, 1)[0];
      this.players.classes.splice(index + 1, 0, target);
      this.changed_players = true;
    },
    deleteClass(e) {
      const index = Number($(e.target).parents('.card').attr('data-index'));
      const classId = this.players.classes[index][0];
      if (this.players.user_classes[classId] && this.players.user_classes[classId].length > 0) {
        this.$_notify('warning', '空でない級は削除できません');
        return;
      }
      if (!_.startsWith(classId, 'new_')) {
        this.players.deleted_classes.push(classId.toString());  // Numberだと送信したときのstatus codeがおかしくなる
      }
      this.players.classes.splice(index, 1);
      this.changed_players = true;
    },
    showAddPlayer(e) {
      const $tgt = $(e.target).parent();
      $tgt.nextAll().show();
      $tgt.next().find('.search').focus();
      $tgt.toggleClass('d-inline-flex')
          .toggleClass('d-none');
    },
    addPlayer(e, _e) {
      let $tgt = null;
      let input = '';
      if (e.target !== undefined) {
        $tgt = $(e.target).parent();
        const $input = $tgt.prev().find('.search');
        input = $input.val();
        $tgt.hide().prev().hide().prev()
            .toggleClass('d-inline-flex')
            .toggleClass('d-none');
      } else {
        $tgt = $(_e).parent();
        $tgt.hide().prev()
            .toggleClass('d-inline-flex')
            .toggleClass('d-none');
        $tgt.next().hide();
        input = e;
      }
      if (input.trim() === '') {
        return;
      }
      const index = Number($tgt.parents('.card').attr('data-index'));
      const classId = this.players.classes[index][0];
      const tempId = `new_${this.new_player_count}`;
      this.new_player_count += 1;
      if (this.players.user_classes[classId] === undefined) {
        // this.players.user_classes[classId] = [];だと変更が検出されない
        this.$set(this.players.user_classes, classId, []);
      }
      this.players.user_classes[classId].push(tempId);
      this.players.users[tempId] = input;
      this.changed_players = true;
    },
    movePlayers() {
      const to = $('#edit_players_dialog select').val();
      if (to === null) {
        this.$_notify('warning', '移動先を選択してください');
      }
      $('#edit_players_dialog input:checked').each((i, e) => {
        const $tgt = $(e);
        const id = $tgt.attr('data-id');
        const index = $tgt.parents('.card').attr('data-index');
        const from = this.players.classes[index][0].toString();
        if (from === to) {
          this.$_notify('warning', `${this.players.users[id]}さんは${this.players.classes[index][1]}に移動できません`);
          return true;
        }
        if (this.players.not_movable[id]) {
          this.$_notify('warning', `${this.players.users[id]}さんは移動できません`);
          return true;
        }
        this.players.user_classes[from] =
          _.filter(this.players.user_classes[from], v => v.toString() !== id);
        this.players.user_classes[to].push(id);
        this.changed_players = true;
        return true;
      });
    },
    deletePlayers() {
      $('#edit_players_dialog input:checked').each((i, e) => {
        const $tgt = $(e);
        const id = $tgt.attr('data-id');
        const index = $tgt.parents('.card').attr('data-index');
        const from = this.players.classes[index][0].toString();
        if (this.players.not_movable[id]) {
          this.$_notify('warning', `${this.players.users[id]}さんは削除できません`);
          $tgt.prop('checked', false);
          return true;
        }
        this.players.user_classes[from] =
          _.filter(this.players.user_classes[from], v => v.toString() !== id);
        delete this.players.users[id];
        this.players.deleted_users.push(id);
        this.changed_players = true;
        return true;
      });
    },
    resetPlayers() {
      this.fetchPlayers();
      const $editPlayersDialog = $('#edit_players_dialog');
      $editPlayersDialog.find('input:checked').prop('checked', false);
      $editPlayersDialog.find('select').val('-1');
      $editPlayersDialog.find('.add').each((i, e) => {
        const $e = $(e);
        if ($e.parent().css('display') !== 'none') {
          $e.click();
        }
      });
    },
    savePlayers() {
      const onSave = () => {
        this.$_notify('保存しました');
        this.changed_players = false;
        $('#edit_players_dialog').modal('hide');
        this.fetch();
      };
      if (!this.changed_players) {
        onSave();
        return;
      }
      axios.put(`/api/result/players/${this.id}`, this.players).then(onSave).catch(() => {
        this.$_notify('danger', '保存に失敗しました');
      });
    },
    setCellHeight() {
      // セルの高さを揃える
      const rows = new Set();
      $('.table-result tbody tr, .table-result thead tr').each((index, elem) => {
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

.dropdown-menu {
  max-height: 50vh;
  overflow-y: auto;
}

#nav-result-tab, #nav-info-tab, #nav-comment-tab {
  &:not(.active) {
    background-color: #f8f9fa;
  }
  &.active {
    border-bottom: 0!important;
  }
}

.unofficial {
  color: green;
}
.date {
  color: brown;
}

.badge-class-name {
  color: white;
  background-color: maroon;
}
.team-prize {
  color: #039;
}

.add {
  border-top-left-radius: 0;
  border-bottom-left-radius: 0;
}
.pb-1px {
  padding-bottom: 1px;
}
</style>
