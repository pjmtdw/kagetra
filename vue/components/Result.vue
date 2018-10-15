<template>
  <main id="container" class="mx-auto">
    <!-- nav, 選手名検索 -->
    <div class="container my-2">
      <div class="row">
        <nav id="nav-result-pages" class="col-12 col-md-8">
          <ul class="pagination justify-content-center justify-content-md-start">
            <li class="page-item active"><span class="page-link p-1 p-sm-2">大会結果</span></li>
            <li class="page-item"><router-link class="page-link p-1 p-sm-2" to="/list">大会一覧</router-link></li>
            <li class="page-item"><router-link class="page-link p-1 p-sm-2" to="/record">個人記録</router-link></li>
            <li class="page-item"><router-link class="page-link p-1 p-sm-2" to="/promotion">昇級履歴</router-link></li>
            <li class="page-item"><router-link class="page-link p-1 p-sm-2" to="/ranking">ランキング</router-link></li>
          </ul>
        </nav>
        <div class="col-12 col-md-4 mt-2 mt-md-0">
          <div class="input-group justify-content-center">
            <div class="input-group-prepend">
              <span class="input-group-text">検索</span>
            </div>
            <PlayerSearch :append="true" :link="true" placeholder="選手名検索"/>
          </div>
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
        <div class="col-12 col-md-4 mb-1" :class="{'invisible': editable === null}">
          <div class="btn-group mb-1" role="group">
            <button v-if="editable" type="button" class="btn btn-success" @click="openAdd">追加</button>
            <button v-if="editable" type="button" class="btn btn-success" @click="openEdit">編集</button>
            <a :href="`result/excel/${id}/${date}_${encodeURI(name)}.xls`" class="btn btn-secondary">保存</a>
          </div>
        </div>
      </div>
    </div>
    <!-- 大会名, 日時, 過去の結果 -->
    <div v-show="loaded" class="mt-4 mb-3">
      <span v-if="official" class="h5 mx-1">&spades;</span>
      <span v-else class="h5 mx-1 text-success">&clubs;</span>
      <span class="h5"><strong>{{ name }}</strong></span>
      <span class="h6 date">@{{ date }}</span>
      <div v-if="event_group_id" class="btn-group mb-1">
        <button type="button" class="btn btn-info py-1" @click="$refs.past_result.open()">過去の結果</button>
        <button type="button" class="btn btn-info py-1 dropdown-toggle dropdown-toggle-split" data-toggle="dropdown"
                aria-haspopup="true" aria-expanded="false"/>
        <div class="dropdown-menu dropdown-menu-right">
          <router-link v-for="g in group" :key="g.id" :to="`/${g.id}`" class="dropdown-item">{{ g.date }} {{ g.name }}</router-link>
        </div>
      </div>
      <PastResultDialog v-if="event_group_id" ref="past_result" :id="event_group_id"/>
    </div>
    <!-- タブ -->
    <nav v-show="loaded" class="mt-2">
      <div class="nav nav-tabs" id="nav-tab" role="tablist">
        <a class="nav-item nav-link border active" data-toggle="tab" href="#nav-result">
          結果
        </a>
        <a class="nav-item nav-link border" data-toggle="tab" href="#nav-info">
          情報
        </a>
        <a class="nav-item nav-link border" data-toggle="tab" href="#nav-comment">
          コメント
          <span v-if="comment_count !== null">({{ comment_count }}{{ has_new_comment ? ' new' : '' }})</span>
        </a>
      </div>
    </nav>
    <!-- タブの中 -->
    <div v-show="loaded" class="tab-content">
      <!-- 結果 -->
      <div id="nav-result" class="tab-pane border border-top-0 bg-white rounded-bottom show active">
        <div id="result-tab-button-wrapper" class="d-flex justify-content-between p-2">
          <div>
            <button id="toggleEdit" class="btn btn-outline-success active mx-1" data-toggle="button" aria-pressed="true" @click="editing = !editing">
              結果編集
            </button>
            <span v-show="editing" class="help-icon ml-1" data-toggle="tooltip" data-placement="top" title="〜回戦をクリックするとその回戦の結果を編集できます"/>
            <button v-if="!isTeamGame" class="btn btn-success mx-1" data-toggle="modal" data-target="#edit_num_person_dialog">人数編集</button>
            <button class="btn btn-success mx-1" data-toggle="modal" data-target="#edit_players_dialog">出場者編集</button>
          </div>
          <button id="toggleAutoUpdate" class="btn btn-info tooltip-button" data-toggle="button" aria-pressed="false" data-placement="top" title="30秒ごとに更新します" @click="toggleAutoUpdate">
            自動更新
          </button>
        </div>
        <div v-for="c in orderedContestClasses" :key="c.id" class="mb-2">
          <span class="badge badge-pill badge-class-name">{{ c.class_name }}</span>
          <span v-if="c.num_person" class="badge badge-secondary">{{ c.num_person }}人</span>
          <div v-for="res in contest_results_conv[c.id]" :key="isTeamGame ? res.team_id : res.class_id" class="d-flex flex-row mb-4">
            <table class="table-name">
              <thead>
                <tr :class="isTeamGame ? `row-team-${res.team_id}` : `row-cls-${res.class_id}`">
                  <th v-if="!isTeamGame" scope="col" class="text-center py-1" :class="{'edit': editing}" @click="editPrize(res.class_id)">{{ editing ? '入賞編集' : '名前' }}</th>
                  <th v-else scope="col" class="text-center py-1" :class="{'edit': editing}" @click="editPrize(res.team_id)">
                    <div>{{ res.header_left.team_name }}</div>
                    <div class="team-prize">{{ res.header_left.team_prize }}</div>
                  </th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="user in res.user_results" :key="user.cuid" :class="`row-${user.cuid}`">
                  <td class="text-center">
                    <router-link tag="span" class="cursor-pointer" :to="`/record/${user.user_name}`">{{ user.user_name }}</router-link >
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
                    <th v-for="(round, i) in res.rounds" scope="col" class="text-center py-1" :class="{'edit': editing}" @click="edit(isTeamGame ? res.team_id : res.class_id, i)">
                      <div>{{ round.name === null ? `${i+1}回戦` : round.name }}</div>
                      <div v-if="isTeamGame">{{ round.op_team_name }}</div>
                    </th>
                    <th v-if="editing" scope="col" class="text-center py-1 edit" @click="edit(isTeamGame ? res.team_id : res.class_id, res.rounds.length)">
                      <div>{{ res.rounds.length+1 }}回戦</div>
                    </th>
                  </tr>
                </thead>
                <tbody>
                  <tr v-for="user in res.user_results" :key="user.cuid" :class="`row-${user.cuid}`">
                    <td v-for="game in user.game_results" class="text-center" :class="`result-${game.result}`">
                      <div v-if="game.result === 'break'"/>
                      <div v-else-if="game.result === 'default_win'">不戦</div>
                      <template v-else>
                        <div>
                          {{ result_str[game.result] }} {{ game.score_str }}
                          <router-link tag="span" class="cursor-pointer" :to="`/record/${game.opponent_name}`">{{ game.opponent_name }}</router-link>
                        </div>
                        <div v-if="game.opponent_belongs">
                          ({{ game.opponent_belongs }})
                          <span v-if="game.comment" class="info-icon" data-toggle="tooltip" data-placement="bottom" :title="game.comment"/>
                        </div>
                        <div v-else-if="game.opponent_order">
                          <span>({{ order_str[game.opponent_order] }})</span>
                          <span v-if="game.comment" class="info-icon" data-toggle="tooltip" data-placement="bottom" :title="game.comment"/>
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
      <div id="nav-info" class="tab-pane border border-top-0 bg-white rounded-bottom pb-3">
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
                  <span v-html="$_timeRange(start_at, end_at)"/>
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
      <div id="nav-comment" class="tab-pane border border-top-0 bg-white rounded-bottom pb-3">
        <div class="d-flex justify-content-between align-items-center">
          <h5 class="m-2">
            <strong>{{ thread_name }}</strong>
          </h5>
          <button id="new-comment-toggle" class="btn btn-success m-2" data-toggle="collapse" href="#new-comment-form"
                  aria-expanded="false" aria-controls="new-comment-form" @click="toggleNewComment">
            書き込む
          </button>
        </div>
        <NewCommentForm id="new-comment-form" class="mx-3 mb-3 mt-2" url="/event/comment/item" :thread-id="id" @done="postDone"/>
        <nav v-if="pages > 1" class="pl-2">
          <ul class="pagination">
            <li v-for="p in pages" :key="p" class="page-item" :class="{'active': p == cur_page}">
              <a class="page-link" href="#" @click.prevent="loadComment">
                {{ p }}
              </a>
            </li>
          </ul>
        </nav>
        <CommentList :comments="list" url="/event/comment/item" item-class="px-2 py-1" @done="fetchComment"/>
      </div>
    </div>

    <!-- 大会追加dialog -->
    <EventEditDialog ref="addDialog" @done="$event.id ? $router.push({path: `${$event.id}`, }) : undefined"/>
    <!-- 大会編集dialog -->
    <EventEditDialog ref="editDialog" @done="fetch"/>
    <!-- 人数編集dialog -->
    <div v-if="!isTeamGame" id="edit_num_person_dialog" class="modal fade" tabindex="-1" role="dialog" aria-hidden="true" @keydown.enter="saveNumPerson">
      <div class="modal-dialog modal-sm" role="document">
        <div class="modal-content">
          <div class="modal-header sticky-top bg-white">
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
          <div class="modal-header sticky-top bg-white">
            <h5 class="modal-title">出場者編集</h5>
            <button type="button" class="close" data-dismiss="modal" aria-label="Close">
              <span aria-hidden="true">&times;</span>
            </button>
          </div>
          <div v-if="players !== null" class="modal-body">
            <div class="d-flex flex-row flex-wrap align-items-center mt-1">
              <div v-if="isTeamGame" class="jumbotron d-flex flex-row flex-wrap w-100 py-3 mb-2">
                <div class="w-100 text-muted">チェックしたチームを操作</div>
                <div class="input-group w-auto col-12 col-sm-auto mb-3 mb-sm-0 mr-2 px-0">
                  <select id="team_to" class="custom-select flex-grow-0 w-auto">
                    <option selected disabled value="-1">--級名--</option>
                    <option v-for="c in players.classes" :key="c[0]" :value="c[0]">{{ c[1] }}</option>
                  </select>
                  <div class="input-group-append">
                    <span class="input-group-text">に</span>
                    <button class="btn btn-outline-success" type="button" @click="moveTeams">移動</button>
                  </div>
                </div>
                <div class="col-12 col-sm-auto px-0">
                  <button class="btn btn-outline-danger" @click="deleteTeams">削除</button>
                </div>
              </div>
              <div class="jumbotron d-flex flex-row flex-wrap w-100 py-3 mb-2">
                <div class="w-100 text-muted">
                  チェックした選手を操作
                  <span v-if="isTeamGame" class="help-icon ml-1" data-toggle="tooltip" data-placement="top" title="将順変更は同チーム内で移動してください"/>
                </div>
                <div class="input-group w-auto col-12 col-sm-auto mb-3 mb-sm-0 mr-2 px-0">
                  <select id="player_to" class="custom-select flex-grow-0 w-auto">
                    <template v-if="!isTeamGame">
                      <option selected disabled value="-1">--級名--</option>
                      <option v-for="c in players.classes" :key="c[0]" :value="c[0]">{{ c[1] }}</option>
                    </template>
                    <template v-else>
                      <option selected disabled value="-1">--チーム名--</option>
                      <option v-for="(tname, tid) in players.teams" :key="tid" :value="tid">{{ tname }}</option>
                    </template>
                  </select>
                  <div class="input-group-append">
                    <span class="input-group-text">に</span>
                    <button class="btn btn-outline-success" type="button" @click="movePlayers">移動</button>
                  </div>
                </div>
                <div class="col-12 col-sm-auto px-0">
                  <button class="btn btn-outline-danger" @click="deletePlayers">削除</button>
                </div>
              </div>
            </div>
            <template v-if="!isTeamGame">
              <div v-for="(c, i) in players.classes" :key="c[0]" class="card mt-4" :data-cindex="i">
                <div class="card-border-title d-flex">
                  <span class="badge badge-pill badge-class-name">{{ c[1] }}</span>
                  <button type="button" class="btn btn-danger btn-sm py-0 ml-auto mr-2" @click="deleteClass(i)">&times;</button>
                </div>
                <div class="card-body d-flex flex-wrap pt-1 pb-2">
                  <div v-for="u in players.user_classes[c[0]]" :key="u" class="form-check my-1 mr-3">
                    <label class="form-check-label">
                      <input type="checkbox" class="form-check-input player mt-1" :data-uid="u">
                      {{ players.users[u] }}
                    </label>
                  </div>
                  <span class="d-inline-flex align-items-center">
                    <button class="btn btn-outline-success btn-sm py-0" @click="showAddPlayer">+</button>
                  </span>
                  <div class="input-group input-group-sm d-none w-auto">
                    <PlayerSearch :clear="true" class-input="form-control-sm" :prepend="true" @done="addPlayer" @enter="addPlayer"/>
                    <span class="input-group-append pb-1px">
                      <button class="btn btn-success btn-sm py-0" @click="addPlayer">追加</button>
                    </span>
                  </div>
                </div>
              </div>
            </template>
            <template v-else>
              <div v-for="(c, i) in players.classes" :key="c[0]" class="card mt-4" :data-cindex="i">
                <div class="card-border-title d-flex">
                  <span class="badge badge-pill badge-class-name">{{ c[1] }}</span>
                  <button type="button" class="btn btn-success btn-sm py-0 ml-auto" data-toggle="tooltip" :title="`${c[1]}にチームを追加`" @click="addTeam(i)">+</button>
                  <button type="button" class="btn btn-danger btn-sm py-0 mx-2" data-toggle="tooltip" :title="`${c[1]}を削除`" @click="deleteClass(i)">&times;</button>
                </div>
                <div class="card-body pt-2 pb-0">
                  <div v-for="t in players.team_classes[c[0]]" :key="t" class="card mb-4" :data-team="t">
                    <div class="card-border-title d-flex">
                      <label class="bg-white"><input type="checkbox" class="team mr-1 mb-0">{{ players.teams[t] }}</label>
                    </div>
                    <div class="card-body d-flex flex-wrap pt-1 pb-2">
                      <div v-for="(u, i) in players.user_teams[t]" :key="u" class="form-check my-1 mr-3">
                        <label class="form-check-label">
                          <input type="checkbox" class="form-check-input player mt-1" :data-uid="u">
                          {{ players.users[u] }}({{ order_str[i+1] }})
                        </label>
                      </div>
                      <span class="d-inline-flex align-items-center">
                        <button class="btn btn-outline-success btn-sm py-0" @click="showAddPlayer">+</button>
                      </span>
                      <div class="input-group input-group-sm d-none w-auto">
                        <PlayerSearch :clear="true" class-input="form-control-sm" :prepend="true" @done="addPlayer" @enter="addPlayer"/>
                        <span class="input-group-append pb-1px">
                          <button class="btn btn-success btn-sm py-0" @click="addPlayer">追加</button>
                        </span>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </template>
            <button class="btn btn-outline-success mt-4" data-toggle="tooltip" title="級を追加" @click="addClass">追加</button>
          </div>
          <div class="modal-footer justify-content-between">
            <button type="button" class="btn btn-outline-danger" @click="resetPlayers">リセット</button>
            <button type="button" class="btn btn-success" @click="savePlayers">保存</button>
          </div>
        </div>
      </div>
    </div>
    <!-- 結果編集dialog -->
    <div id="edit_result_dialog" class="modal fade" tabindex="-1" role="dialog" aria-hidden="true" @keydown.shift.enter="saveResult">
      <div class="modal-dialog modal-lg" role="document">
        <div class="modal-content">
          <div class="modal-header sticky-top bg-white">
            <h5 class="modal-title">
              結果編集
              ({{ `${edit_results.name} ${edit_results.round_name === null ? `${edit_results.round + 1}回戦` : edit_results.round_name}` }})
            </h5>
            <button type="button" class="close" data-dismiss="modal" aria-label="Close">
              <span aria-hidden="true">&times;</span>
            </button>
          </div>
          <div class="modal-body">
            <template v-if="!isTeamGame">
              <div class="form-inline mb-3">
                <label>
                  回戦名
                  <input v-model="edit_results.round_name" class="form-control ml-1" type="text" placeholder="決勝 or 準決勝">
                </label>
                <button v-show="edit_results.exists_loser" class="btn ml-2" :class="show_loser ? 'btn-secondary' : 'btn-outline-secondary'" @click="show_loser = !show_loser">負けた人も表示</button>
              </div>
              <div v-for="u in show_loser ? edit_results.all : edit_results.remaining" :key="`${u.cuid}-${edit_results.round}`" class="jumbotron form-row d-flex flex-row flex-wrap align-items-center w-100 py-2 px-1 mb-3">
                <span class="col-5 col-sm-3 col-lg-2 text-right">{{ u.user_name }}</span>
                <select v-model="u.result.result" class="custom-select col-4 col-sm-3 col-lg-1">
                  <option value="-1">--</option>
                  <option v-for="(r, k) in results_jp" :key="k" :value="k">{{ r }}</option>
                </select>
                <input v-model="u.result.score_str" type="text" class="form-control col-3 col-sm-3 col-lg-1" placeholder="枚数">
                <div class="w-100 d-none d-sm-block d-lg-none"/>
                <PlayerSearch v-model="u.result.opponent_name" class="col-5 col-sm-3 col-lg-2 px-0" :bind="true" placeholder="対戦相手"/>
                <input v-model="u.result.opponent_belongs" type="text" class="form-control col-7 col-sm-4 col-lg-2" placeholder="所属会">
                <input v-model="u.result.comment" type="text" class="form-control col-12 col-sm-5 col-lg-3" placeholder="コメント">
              </div>
            </template>
            <template v-else>
              <div class="form-inline mb-3">
                <label>
                  回戦名
                  <input v-model="edit_results.round_name" class="form-control ml-sm-1" type="text" placeholder="決勝/順位決定戦など">
                </label>
                <label class="ml-sm-2">
                  相手チーム
                  <input v-model="edit_results.op_team_name" class="form-control ml-sm-1" type="text" placeholder="決勝/順位決定戦など">
                </label>
              </div>
              <div v-for="u in edit_results.players" :key="`${u.cuid}-${edit_results.round}`" class="jumbotron form-row d-flex flex-row flex-wrap align-items-center w-100 py-2 px-1 mb-3">
                <span class="col-5 col-sm-3 col-lg-2 text-right">{{ u.user_name }}</span>
                <select v-model="u.result.result" class="custom-select col-4 col-sm-3 col-lg-1">
                  <option value="break">--</option>
                  <option v-for="(r, k) in results_jp" :key="k" :value="k">{{ r }}</option>
                </select>
                <input v-model="u.result.score_str" type="text" class="form-control col-3 col-sm-3 col-lg-1" placeholder="枚数">
                <div class="w-100 d-none d-sm-block d-lg-none"/>
                <PlayerSearch v-model="u.result.opponent_name" class="col-5 col-sm-3 col-lg-2 px-0" :bind="true" placeholder="対戦相手"/>
                <select v-model="u.result.opponent_order" class="custom-select col-7 col-sm-4 col-lg-2">
                  <option v-for="(o, i) in order_str" :key="i" :value="i">{{ o === null ? '--' : o }}</option>
                </select>
                <input v-model="u.result.comment" type="text" class="form-control col-12 col-sm-5 col-lg-3" placeholder="コメント">
              </div>
            </template>
          </div>
          <div class="modal-footer d-flex">
            <!-- <button type="button" class="btn btn-outline-danger" @click="resetResult">リセット</button> -->
            <button type="button" class="btn btn-success ml-auto" @click="saveResult">保存</button>
          </div>
        </div>
      </div>
    </div>
    <!-- 入賞編集dialog -->
    <div id="edit_prize_dialog" class="modal fade" tabindex="-1" role="dialog" aria-hidden="true" @keydown.shift.enter="savePrize">
      <div class="modal-dialog modal-lg" role="document">
        <div class="modal-content">
          <div class="modal-header sticky-top bg-white">
            <h5 class="modal-title">
              入賞編集
              ({{ edit_prizes.name }})
            </h5>
            <button type="button" class="close" data-dismiss="modal" aria-label="Close">
              <span aria-hidden="true">&times;</span>
            </button>
          </div>
          <div class="modal-body">
            <template v-if="!isTeamGame">
              <small class="text-muted mb-1">'優勝(昇級)'のように昇級やダッシュなどは()で囲って下さい</small>
              <div v-for="u in edit_prizes.players" :key="u.cuid" class="jumbotron form-row d-flex flex-row flex-wrap align-items-center w-100 py-2 px-1 mb-3">
                <span class="ml-2 mr-1">{{ u.user_name }}</span>
                <input v-model="u.prize.prize" type="text" class="form-control w-auto" placeholder="入賞">
                <div class="w-100 d-block d-sm-none"/>
                <div class="form-inline ml-auto ml-md-2 mr-1">
                  <span>ポイント</span>
                  <select v-model="u.prize.point" class="custom-select">
                    <option v-for="p in points" :key="p" :value="p">{{ p }}</option>
                  </select>
                </div>
                <div class="form-inline ml-auto ml-md-2 mr-1">
                  <span>会内ポイント</span>
                  <select v-model="u.prize.point_local" class="custom-select">
                    <option v-for="p in local_points" :key="p" :value="p">{{ p }}</option>
                  </select>
                </div>
              </div>
            </template>
            <template v-else>
              <div class="form-inline">
                <span>チーム成績</span>
                <input v-model="edit_prizes.team_prize" class="form-control ml-1" type="text">
              </div>
              <small class="form-text text-muted mb-3">'優勝(昇級)'のように昇級や陥落などは()で囲って下さい</small>
              <div v-for="u in edit_prizes.players" :key="u.cuid" class="jumbotron form-row d-flex flex-row flex-wrap align-items-center w-100 py-2 px-1 mb-3">
                <span class="ml-2 mr-1">{{ u.user_name }}</span>
                <input v-model="u.prize.prize" type="text" class="form-control w-auto" placeholder="入賞">
                <div class="w-100 d-block d-sm-none"/>
                <div class="form-inline ml-auto ml-md-2 mr-1">
                  <span>ポイント</span>
                  <select v-model="u.prize.point" class="custom-select">
                    <option v-for="p in points" :key="p" :value="p">{{ p }}</option>
                  </select>
                </div>
                <div class="form-inline ml-auto ml-md-2 mr-1">
                  <span>会内ポイント</span>
                  <select v-model="u.prize.point_local" class="custom-select">
                    <option v-for="p in local_points" :key="p" :value="p">{{ p }}</option>
                  </select>
                </div>
              </div>
            </template>
          </div>
          <div class="modal-footer d-flex">
            <button type="button" class="btn btn-success ml-auto" @click="savePrize">保存</button>
          </div>
        </div>
      </div>
    </div>
  </main>
</template>
<script>
import PlayerSearch from './subcomponents/PlayerSearch.vue';
import PastResultDialog from './subcomponents/PastResultDialog.vue';
import EventEditDialog from './subcomponents/EventEditDialog.vue';
import CommentList from './subcomponents/CommentList.vue';

export default {
  components: {
    PlayerSearch,
    PastResultDialog,
    EventEditDialog,
    CommentList,
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
      results_jp: $.util.results_jp,
      result_str: $.util.result_str,
      order_str: $.util.order_str,
      points: $.util.points,
      local_points: $.util.local_points,
      // auto update
      updating: false,
      updater: null,
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
      list: [],
      has_new_comment: false,
      // edit players
      changed_num_person: false,
      changed_players: false,
      players: null,
      new_class_count: 0,
      new_player_count: 0,
      new_team_count: 0,
      // edit result
      editing: false,
      edit_results: {},
      show_loser: false,
      edit_prizes: {},
    };
  },
  computed: {
    isTeamGame() {
      return this.team_size > 1;
    },
    weekday() {
      return $.util.getWeekDay(this.date);
    },
    orderedContestClasses() {
      if (_.isNull(this.contest_classes)) return null;
      const ret = [];
      _.each(this.contest_results, (r) => {
        ret.push(_.assign(this.contest_classes[r.class_id], { id: r.class_id }));
      });
      return ret;
    },
    contest_results_conv() {
      const ret = {};
      _.forEach(this.contest_results, (v) => {
        const cid = v.class_id;
        if (ret[cid] === undefined) ret[cid] = [];
        ret[cid].push(v);
      });
      return ret;
    },
  },
  watch: {
    contestId() {
      this.players = null;  // これはfetchでは変更されず遷移してもそのままなのでnullにしないとエラーになる
      if (this.editing) {
        this.editing = false;
        $('#toggleEdit').button('toggle');
      }
      if (this.updating) {
        this.toggleAutoUpdate();
        $('#toggleAutoUpdate').button('toggle');
      }
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
    $(document).on('show.bs.modal', () => {
      $('[data-toggle="tooltip"]').tooltip('hide');
    });
  },
  updated() {
    this.setCellHeight();
    $('[data-toggle="tooltip"], .tooltip-button').tooltip();
  },
  methods: {
    fetch() {
      const baseUrl = '/result/contest';
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
    update() {
      const baseUrl = '/result/contest';
      const url = this.contestId === null ? `${baseUrl}/latest` : `${baseUrl}/${this.contestId}`;
      axios.get(url).then((res) => {
        _.forEach(res.data, (v, key) => {
          this[key] = v;
        });
        // 自身を削除
        this.group = this.group.filter(v => v.id !== this.id);
      }).catch(() => {
        this.$_notify('danger', '大会結果の取得に失敗しました');
      });
    },
    toggleAutoUpdate() {
      if (this.updating) {
        this.updating = false;
        clearInterval(this.updater);
      } else {
        this.updating = true;
        this.update();
        this.updater = setInterval(this.update, 30000);
      }
    },
    fetchDetail() {
      const url = `/event/item/${this.id}?detail=true&no_participant=true`;
      axios.get(url).then((res) => {
        _.forEach(['formal_name', 'start_at', 'end_at', 'place', 'description', 'attached', 'editable'], (v) => {
          this[v] = res.data[v];
        });
      }).catch(() => {
        this.$_notify('danger', '大会情報の取得に失敗しました');
      });
    },
    // 結果
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
    // コメント
    fetchComment() {
      const contestId = this.id;
      const page = this.cur_page;
      const baseUrl = `/event/comment/list/${contestId}`;
      const url = page === 1 ? baseUrl : `${baseUrl}?page=${page}`;
      axios.get(url).then((res) => {
        _.forEach(res.data, (v, key) => {
          this[key] = v;
        });
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

    // 人数編集
    saveNumPerson() {
      const $dialog = $('#edit_num_person_dialog');
      const $form = $dialog.find('form');
      const onSave = () => {
        $form.removeClass('was-validated');
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
      axios.post('/result/num_person', { data }).then(onSave).catch(() => {
        this.$_notify('danger', '保存に失敗しました');
      });
    },

    // 出場者編集 (id系をstringで扱ってるのは追加したidを'new_[0-9]'という形にするから)
    fetchPlayers() {
      axios.get(`/result/players/${this.id}`).then((res) => {
        this.players = res.data;
        this.players.deleted_classes = [];
        this.players.deleted_teams = [];
        this.players.deleted_users = [];
      }).catch(() => {
        this.$_notify('danger', '出場者情報の取得に失敗しました');
      });
    },
    addClass(e) {
      this.$_prompt('級名を入力してください').then((res) => {
        const tempId = `new_${this.new_class_count}`;
        if (this.isTeamGame) this.players.classes.push([tempId, res]);
        else {
          const index = Number($(e.target).closest('.card').attr('data-cindex'));
          this.players.classes.splice(index + 1, 0, [tempId, res]);
        }
        this.new_class_count += 1;
        this.changed_players = true;
      }).always(() => {
        $('body').addClass('modal-open');
      });
    },
    deleteClass(index) {
      const classId = this.players.classes[index][0];
      const classes = this.isTeamGame ? this.players.team_classes : this.players.user_classes;
      if (classes[classId] && classes[classId].length > 0) {
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
      $tgt.toggleClass('d-inline-flex')
          .toggleClass('d-none')
          .next()
          .toggleClass('d-inline-flex')
          .toggleClass('d-none');
      $tgt.next().find('input[type="search"]').focus();
    },
    addPlayer(e, _e) {
      let $tgt = null;
      let input = '';
      if (e.target !== undefined) {
        $tgt = $(e.target).parent();
        const $input = $tgt.prev().find('input[type="search"]');
        input = $input.val();
        $input.val('');
        $tgt.parent()
            .toggleClass('d-inline-flex')
            .toggleClass('d-none')
            .prev()
            .toggleClass('d-inline-flex')
            .toggleClass('d-none');
      } else {
        $tgt = $(_e).parent();
        $tgt.toggleClass('d-inline-flex')
            .toggleClass('d-none')
            .prev()
            .toggleClass('d-inline-flex')
            .toggleClass('d-none');
        input = e;
      }
      if (input.trim() === '') {
        return;
      }
      if (this.isTeamGame) {
        const teamId = $tgt.closest('.card').attr('data-team');
        const tempId = `new_${this.new_player_count}`;
        this.new_player_count += 1;
        this.players.user_teams[teamId].push(tempId);
        this.players.users[tempId] = input;
      } else {
        const index = Number($tgt.closest('.card').attr('data-cindex'));
        const classId = this.players.classes[index][0];
        const tempId = `new_${this.new_player_count}`;
        this.new_player_count += 1;
        if (this.players.user_classes[classId] === undefined) {
          this.$set(this.players.user_classes, classId, []);
        }
        this.players.user_classes[classId].push(tempId);
        this.players.users[tempId] = input;
      }
      this.changed_players = true;
    },
    movePlayers() {
      const selected = $('#edit_players_dialog input.player:checked');
      if (selected.length === 0) this.$_notify('warning', '選手が選択されていません');
      const to = $('#player_to').val();
      if (to === null) {
        this.$_notify('warning', '移動先を選択してください');
        return;
      }
      selected.each((i, e) => {
        const $tgt = $(e);
        const playerId = $tgt.attr('data-uid');
        if (this.players.not_movable[playerId]) {
          this.$_notify('warning', `${this.players.users[playerId]}さんは移動できません`);
          return true;
        }
        if (this.isTeamGame) {
          const from = $tgt.closest('.card').attr('data-team');
          this.players.user_teams[from] =
            _.filter(this.players.user_teams[from], v => v.toString() !== playerId);
          this.players.user_teams[to].push(playerId);
        } else {
          const index = Number($tgt.closest('.card').attr('data-cindex'));
          const from = this.players.classes[index][0].toString();
          if (from === to) {
            this.$_notify('warning', `${this.players.users[playerId]}さんは${this.players.classes[index][1]}に移動できません`);
            return true;
          }
          this.players.user_classes[from] =
            _.filter(this.players.user_classes[from], v => v.toString() !== playerId);
          this.players.user_classes[to].push(playerId);
        }
        this.changed_players = true;
        return true;
      });
    },
    deletePlayers() {
      const selected = $('#edit_players_dialog input.player:checked');
      if (selected.length === 0) this.$_notify('warning', '選手が選択されていません');
      selected.each((i, e) => {
        const $tgt = $(e);
        const playerId = $tgt.attr('data-uid');
        if (this.players.not_movable[playerId]) {
          this.$_notify('warning', `${this.players.users[playerId]}さんは削除できません`);
          $tgt.prop('checked', false);
          return true;
        }
        if (this.isTeamGame) {
          const teamId = $tgt.closest('.card').attr('data-team');
          this.players.user_teams[teamId] =
            _.filter(this.players.user_teams[teamId], v => v.toString() !== playerId);
        } else {
          const index = $tgt.closest('.card').attr('data-cindex');
          const from = this.players.classes[index][0].toString();
          this.players.user_classes[from] =
            _.filter(this.players.user_classes[from], v => v.toString() !== playerId);
        }
        delete this.players.users[playerId];
        if (!_.startsWith(playerId, 'new_')) {
          this.players.deleted_users.push(playerId);
        }
        this.changed_players = true;
        return true;
      });
    },
    resetPlayers() {
      this.fetchPlayers();
      const $editPlayersDialog = $('#edit_players_dialog');
      $editPlayersDialog.find('input:checked').prop('checked', false);
      $editPlayersDialog.find('select').val('-1');
      $editPlayersDialog.find('.add-player').each((i, e) => {
        const $e = $(e);
        if ($e.parent().css('display') !== 'none') {
          $e.click();
        }
      });
    },
    savePlayers() {
      const onSave = () => {
        this.changed_players = false;
        $('#edit_players_dialog').modal('hide');
        this.fetch();
      };
      if (!this.changed_players) {
        onSave();
        return;
      }
      axios.put(`/result/players/${this.id}`, this.players).then(onSave).catch(() => {
        this.$_notify('danger', '保存に失敗しました');
      });
    },
    addTeam(index) {
      this.$_prompt('チーム名を入力してください').then((res) => {
        const classId = this.players.classes[index][0];
        const tempId = `new_${this.new_team_count}`;
        this.players.team_classes[classId].push(tempId);
        this.$set(this.players.teams, tempId, res);
        this.$set(this.players.user_teams, tempId, []);
        this.new_team_count += 1;
        this.changed_players = true;
      }).always(() => {
        $('body').addClass('modal-open');
      });
    },
    moveTeams() {
      const selected = $('#edit_players_dialog input.team:checked');
      if (selected.length === 0) this.$_notify('warning', 'チームが選択されていません');
      const to = $('#team_to').val();
      if (to === null) {
        this.$_notify('warning', '移動先を選択してください');
        return;
      }
      selected.each((i, e) => {
        const $tgt = $(e);
        const teamId = $tgt.closest('.card').attr('data-team');
        const index = Number($tgt.closest('.card').parent().closest('.card').attr('data-cindex'));
        const from = this.players.classes[index][0].toString();
        if (from === to) {
          this.$_notify('warning', `${this.players.teams[teamId]}は${this.players.classes[index][1]}に移動できません`);
          return true;
        }
        this.players.team_classes[from] =
          _.filter(this.players.team_classes[from], v => v.toString() !== teamId);
        this.players.team_classes[to].push(teamId);
        this.changed_players = true;
        return true;
      });
    },
    deleteTeams() {
      const selected = $('#edit_players_dialog input.team:checked');
      if (selected.length === 0) this.$_notify('warning', 'チームが選択されていません');
      selected.each((i, e) => {
        const $tgt = $(e);
        const teamId = $tgt.closest('.card').attr('data-team');
        const index = Number($tgt.closest('.card').parent().closest('.card').attr('data-cindex'));
        const from = this.players.classes[index][0].toString();
        this.players.team_classes[from] =
            _.filter(this.players.team_classes[from], v => v.toString() !== teamId);
        delete this.players.teams[teamId];
        if (!_.startsWith(teamId, 'new_')) {
          this.players.deleted_teams.push(teamId);
        }
        this.changed_players = true;
        return true;
      });
    },

    // 結果編集
    edit(id, round) {
      // round: from 0
      if (!this.editing) return;
      const unselected = '-1';
      const editResults = {};
      if (!this.isTeamGame) {
        editResults.class_id = id;
        editResults.name = this.contest_classes[id].class_name;
        const results = this.contest_results_conv[id][0];
        editResults.round = round;
        editResults.round_name = (results.rounds[round] && results.rounds[round].name)
          ? results.rounds[round].name : null;
        const isLoser = (user) => {
          if (round === 0) return false;
          if (user.game_results[round] !== undefined) return false;
          if (user.game_results[round - 1] && user.game_results[round - 1].result !== 'lose') return false;
          return true;
        };
        editResults.remaining = _.filter(results.user_results, v => !isLoser(v));
        editResults.remaining = _.map(editResults.remaining, v => ({
          cuid: v.cuid,
          user_name: v.user_name,
          result: _.clone(v.game_results[round]) || { result: unselected },
        }));
        const losers = _.map(_.filter(results.user_results, isLoser), v => ({
          cuid: v.cuid,
          user_name: v.user_name,
          result: _.clone(v.game_results[round]) || { result: unselected },
        }));
        editResults.all = _.concat(editResults.remaining, losers);
        editResults.exists_loser = losers.length > 0;
      } else {
        editResults.team_id = id;
        const results = _.find(this.contest_results, { team_id: id });
        editResults.class_id = results.class_id;
        editResults.round = round;
        editResults.name = results.header_left.team_name;
        editResults.round_name = (results.rounds[round] && results.rounds[round].name)
          ? results.rounds[round].name : null;
        editResults.op_team_name = (results.rounds[round] && results.rounds[round].op_team_name)
          ? results.rounds[round].op_team_name : null;
        editResults.players = _.map(results.user_results, (v) => {
          const result = _.clone(v.game_results[round]);
          if (!result.opponent_order) result.opponent_order = '0';
          return {
            cuid: v.cuid,
            user_name: v.user_name,
            result,
          };
        });
      }
      this.edit_results = editResults;
      $('#edit_result_dialog').modal('show');
    },
    saveResult() {
      const e = this.edit_results;
      const data = {};
      if (!this.isTeamGame) {
        const unselected = '-1';
        const classId = e.class_id;
        const { round } = e;
        const userResults = this.contest_results_conv[classId][0].user_results;
        data.class_id = classId;
        data.round = round + 1;
        data.round_name = e.round_name || null;
        // 変更箇所のみを残す
        this.$_assert(userResults.length === e.all.length);
        data.results = _.map(e.all, (player) => {
          const prevRes = _.find(userResults, { cuid: player.cuid }).game_results[round];
          if (prevRes === undefined && player.result.result === unselected) return false;
          if (player.result.result === unselected) player.result.result = null;
          if (_.isEqual(player.result, prevRes)) return false;
          const ret = player.result;
          ret.cuid = player.cuid;
          return ret;
        });
        data.results = _.filter(data.results);
      } else {
        const teamId = e.team_id;
        const { round } = e;
        const userResults = _.find(this.contest_results, { team_id: teamId }).user_results;
        data.class_id = e.class_id;
        data.team_id = teamId;
        data.round = round + 1;
        data.round_name = e.round_name || null;
        data.round_kind = 'team';
        data.op_team_name = e.op_team_name || null;
        // 変更箇所のみを残す
        this.$_assert(userResults.length === e.players.length);
        data.results = _.map(e.players, (player) => {
          const prevRes = _.find(userResults, { cuid: player.cuid }).game_results[round];
          if (player.result.opponent_order === '0') delete player.result.opponent_order;
          if (_.isEqual(player.result, prevRes)) return false;
          if (player.result.result === 'break') player.result.result = null;
          const ret = player.result;
          ret.cuid = player.cuid;
          return ret;
        });
        data.results = _.filter(data.results);
      }
      axios.post('/result/update_round', data).then(() => {
        $('#edit_result_dialog').modal('hide');
        this.fetch();
      }).catch(() => {
        this.$_notify('danger', '更新に失敗しました');
      });
    },

    // 入賞編集
    editPrize(id) {
      const editPrizes = {};
      if (!this.isTeamGame) {
        editPrizes.class_id = id;
        editPrizes.name = this.contest_classes[id].class_name;
        editPrizes.players = _.cloneDeep(this.contest_results_conv[id][0].user_results);
        _.each(editPrizes.players, (p) => {
          if (p.prize === undefined) {
            p.prize = {
              prize: '',
              point: 0,
              point_local: 0,
            };
          }
        });
      } else {
        editPrizes.team_id = id;
        const results = _.find(this.contest_results, { team_id: id });
        editPrizes.class_id = results.class_id;
        editPrizes.name = results.header_left.team_name;
        editPrizes.team_prize = results.header_left.team_prize || null;
        editPrizes.players = _.cloneDeep(results.user_results);
        _.each(editPrizes.players, (p) => {
          if (p.prize === undefined) {
            p.prize = {
              prize: '',
              point_local: 0,
            };
          }
        });
      }
      this.edit_prizes = editPrizes;
      $('#edit_prize_dialog').modal('show');
    },
    savePrize() {
      const e = this.edit_prizes;
      const data = {};
      if (!this.isTeamGame) {
        data.class_id = e.class_id;
        data.prizes = _.map(e.players, p => _.assign(p.prize, { cuid: p.cuid }));
      } else {
        data.class_id = e.class_id;
        data.team_id = e.team_id;
        data.team_prize = e.team_prize;
        data.prizes = _.map(e.players, p => _.assign(p.prize, { cuid: p.cuid }));
      }
      axios.post('/result/update_prize', data).then(() => {
        $('#edit_prize_dialog').modal('hide');
        this.fetch();
      }).catch(() => {
        this.$_notify('danger', '更新に失敗しました');
      });
    },

    openAdd() {
      this.$refs.addDialog.open({ contest: true });
    },
    openEdit() {
      this.$refs.editDialog.open({ id: this.id, contest: true });
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

.dropdown-menu {
  max-height: 50vh;
  overflow-y: auto;
  -webkit-overflow-scrolling: touch;
}

.date {
  color: brown;
}

.nav-tabs a {
  &:not(.active) {
    background-color: #f8f9fa;
  }
  &.active {
    border-bottom: 0!important;
  }
}

#result-tab-button-wrapper button {
  // @include media-breakpoint-down(sm)
  @media screen and (max-width: 575px) {
    padding: .25rem .5rem;
  }
}

.badge-class-name {
  color: white;
  background-color: maroon;
}

#nav-result {
  .team-prize {
    color: #039;
  }

  .edit {
    cursor: pointer;
    background: linear-gradient(#ffddcc, #f7bd8e);
    &:hover {
      background: linear-gradient(#f5cfb0, #f5b17a);
    }
  }
}

</style>
