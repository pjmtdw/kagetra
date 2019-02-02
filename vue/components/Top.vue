<template>
  <main id="container" class="container mx-auto">
    <!-- ログイン・メッセージ, 予定表 -->
    <div v-if="last_login" class="row mt-3">
      <div class="col-12 col-md-6 pr-3">
        <div class="jumbotron bg-light shadow-sm p-3">
          <span>最終ログイン: {{ last_login.last }}</span>
          <a v-if="last_login.can_relogin" href="#" @click="relogin">(+{{ last_login.from_last }}分)</a>
          <span v-else-if="last_login.from_last >= 5" class="text-muted">(+{{ last_login.from_last }}分)</span>
          <span>, 今月ログイン: {{ log_mon }}</span>
          <div v-if="today_contests && today_contests.length > 0">
            <span>本日の大会</span>
            <a v-for="c in today_contests" :key="c.id" class="ml-1" :href="`/result#/${c.id}`">{{ c.name }}</a>
          </div>
          <div v-if="new_events && new_events.length > 0">
            <span>新規大会行事追加{{ new_events.length }}件</span>
            <a v-for="e in new_events" :key="e.id" class="ml-1" href="#" @click.prevent="openInfo(e.id)">{{ e.name }}</a>
          </div>
          <div v-if="bbs && bbs.length > 0">
            <span>掲示板に新着{{ bbs.length }}件</span>
            <a v-for="v in bbs" :href="`/bbs#/${v.page}`">{{ v.title }}</a>
          </div>
          <div v-if="event_comment && event_comment.length > 0">
            <span>大会行事コメントに新着{{ event_comment.length }}件</span>
            <a v-for="e in event_comment" :key="e.id" class="ml-1" href="#" @click.prevent="openComment(e.id)">{{ e.name }}</a>
          </div>
          <div v-if="result_comment && result_comment.length > 0">
            <span>大会結果コメントに新着{{ result_comment.length }}件</span>
            <a v-for="r in result_comment" :key="r.id" class="ml-1" :href="`/result#/${r.id}`">{{ r.name }}</a>
          </div>
          <div v-if="ev_done_comment && ev_done_comment.length > 0">
            <span>過去行事コメントに新着{{ ev_done_comment.length }}件</span>
            <a v-for="e in ev_done_comment" href="/schedule#/past_event" class="ml-1">{{ e.name }}</a>
          </div>
          <div v-if="wiki && wiki.length > 0">
            <span>Wikiコメントに新着{{ wiki.length }}件</span>
            <a v-for="w in wiki" :href="`/wiki#/${w.id}/comment`" class="ml-1">{{ w.title }}</a>
          </div>
          <div v-if="participants && participants.length > 0">
            <span>大会行事の新規登録者: </span>
            <template v-for="p in participants">
              <a href="#" @click.prevent="openInfo(p[0])">{{ p[1] }}</a>
              <span class="mr-1">&rArr; {{ p[2].join(', ') }}</span>
            </template>
          </div>
        </div>
      </div>
      <div v-for="day in days" :key="day.date" class="col-4 col-md-2 px-1">
        <ScheduleItem :day="day" :show-more="true" @click.native="openDetail(day)"/>
      </div>
    </div>
    <!-- 締切が迫る/過ぎた, 今日の一枚 -->
    <div v-if="eventList" class="row justify-content-center mt-3">
      <div class="col-12 col-md-6">
        <div v-if="nearDeadlineEvents && nearDeadlineEvents.length > 0" class="card my-1">
          <div class="card-body">
            <h6 class="card-subtitle text-muted">締切が迫っています</h6>
            <div v-for="e in nearDeadlineEvents" :key="e.id" class="d-flex flex-row pl-1">
              <a href="#" @click.prevent="openInfo(e.id)">{{ e.name }}</a>
              <nav class="nav nav-pills ml-4">
                <a v-for="c in e.choices" :key="c.id" href="#" class="nav-item nav-link px-1 py-0" :class="{ active: e.choice === c.id, 'bg-secondary': e.choice === c.id && !c.positive }"
                   @click.prevent="select(e, c)">
                  {{ c.name }}
                </a>
              </nav>
            </div>
          </div>
        </div>
        <div v-if="afterDeadlineEvents && afterDeadlineEvents.length > 0" class="card my-1">
          <div class="card-body">
            <h6 class="card-subtitle text-muted mb-2">締切が過ぎました</h6>
            <table class="table table-sm table-borderless w-auto mb-0">
              <tr v-for="e in afterDeadlineEvents" :key="e.id">
                <td class="pr-5">
                  <a href="#" @click.prevent="openInfo(e.id)">{{ e.name }}</a>
                </td>
                <td class="text-success text-right font-weight-bold pl-5">
                  {{ -e.deadline_day }}
                </td>
                <td>
                  日経過
                </td>
              </tr>
            </table>
          </div>
        </div>
      </div>
      <div class="col-10 col-md-6 mt-2 mt-md-0 d-flex flex-row justify-content-center">
        <div class="d-inline-block border rounded daily-photo p-2">
          <div class="text-center text-muted">
            今日の一枚
          </div>
          <a :href="`/album#/${daily_photo.id}`">
            <img :src="`/static/album/thumb/${daily_photo.thumb.id}`" alt="今日の一枚" :width="daily_photo.thumb.width" :height="daily_photo.thumb.height">
          </a>
        </div>
      </div>
    </div>
    <!-- 大会追加・行事追加, 並び替え -->
    <div v-show="eventList" class="row mt-3">
      <div class="col-12 col-md-6">
        <div v-if="sub_admin" class="d-flex flex-row">
          <button class="btn btn-success" @click="openEdit({ contest: true })">大会追加</button>
          <button class="btn btn-success ml-2" @click="openEdit({ contest: false })">行事追加</button>
        </div>
      </div>
      <div class="col-12 col-md-6 d-flex flex-row align-items-center" :class="{ 'mt-2 mt-md-0': sub_admin }">
        <div class="text-muted mr-2">並び替え</div>
        <nav class="nav nav-pills">
          <a v-for="o in orders" :key="o.value" href="#" class="nav-item nav-link p-1" :class="{ active: order === o.value }" @click.prevent="order = o.value">
            {{ o.name }}
          </a>
        </nav>
      </div>
    </div>
    <!-- イベントリスト -->
    <div v-if="eventList" class="row mt-3">
      <div v-for="e in sortedEventList" :key="e.id" class="col-12 col-md-6 py-2">
        <div class="card" :class="{ 'bg-light': !e.public }">
          <h5 class="card-header">
            <template v-if="e.kind === 'contest'">
              <span v-if="e.official">&spades;</span>
              <span v-else class="text-success">&clubs;</span>
            </template>
            <span v-else-if="e.kind === 'party'" class="text-danger">&hearts;</span>
            <span v-else class="text-primary">&diams;</span>
            <span>{{ e.name }}</span>
          </h5>
          <div class="card-body">
            <div class="d-flex flex-row">
              <div>
                <small class="text-muted">開催日</small>
                <span class="font-weigt-bold" v-html="formatDate(e.date)"/>
              </div>
              <div class="ml-auto">
                <template v-if="e.forbidden">
                  <small class="text-black-50">締切</small>
                  <span v-if="e.deadline === null">なし</span>
                  <span v-else-if="e.deadline_day < 0" class="text-black-50">過ぎました</span>
                  <span v-else-if="e.deadline_day === 0" class="text-muted">今日</span>
                  <span v-else-if="e.deadline_day === 1" class="text-muted">明日</span>
                  <span v-else class="text-muted">あと{{ e.deadline_day }}日</span>
                </template>
                <template v-else>
                  <small class="text-muted">締切</small>
                  <span v-if="e.deadline === null">なし</span>
                  <span v-else-if="e.deadline_day < 0" class="text-muted">過ぎました</span>
                  <span v-else-if="e.deadline_day === 0">今日</span>
                  <span v-else-if="e.deadline_day === 1">明日</span>
                  <span v-else>あと{{ e.deadline_day }}日</span>
                </template>
              </div>
            </div>
            <div v-if="e.deadline === null || e.deadline_day >= 0" class="mt-2">
              <span v-if="e.forbidden" class="text-muted">
                貴方は登録不可です
              </span>
              <nav v-else class="nav nav-pills">
                <a v-for="c in e.choices" :key="c.id" href="#" class="nav-item nav-link px-1 py-0" :class="{ active: e.choice === c.id, 'bg-secondary': e.choice === c.id && !c.positive }"
                   @click.prevent="select(e, c)">
                  {{ c.name }}
                </a>
              </nav>
            </div>
            <div class="mt-2">
              <span class="text-muted">登録数</span>
              <span>{{ e.participant_count }}名</span>
            </div>
            <div class="d-flex flex-row mt-3">
              <button v-if="e.editable" class="btn btn-success" @click="openEdit({ id: e.id, contest: e.kind === 'contest' })">編集</button>
              <button v-if="e.event_group_id" class="btn btn-info ml-2" @click="$refs[`past_result_${e.id}`][0].open()">過去の結果</button>
              <button class="btn btn-info ml-2" @click="openInfo(e.id)">情報</button>
              <button class="btn btn-info ml-2" @click="openComment(e.id)">コメント({{ e.comment_count }})</button>
            </div>
          </div>
        </div>
        <PastResultDialog v-if="e.event_group_id" :ref="`past_result_${e.id}`" :id="e.event_group_id"/>
      </div>
    </div>

    <!-- dialog -->
    <DayDetailDialog ref="detailDialog" @openinfo="openInfo" @opencomment="openComment"/>
    <EventInfoDialog ref="infoDialog" @openedit="openEdit" @opencomment="openComment"/>
    <EventEditDialog ref="editDialog" @done="fetch"/>
    <EventCommentDialog ref="commentDialog" @openinfo="openInfo" @done="fetch"/>
  </main>
</template>
<script>
/* global g_sub_admin, g_daily_photo */

import ScheduleItem from './subcomponents/ScheduleItem.vue';
import DialogMixin from './subcomponents/DialogMixin';
import PastResultDialog from './subcomponents/PastResultDialog.vue';

export default {
  components: {
    ScheduleItem,
    PastResultDialog,
  },
  mixins: [DialogMixin],
  data() {
    return {
      sub_admin: g_sub_admin,
      daily_photo: g_daily_photo,

      nearDeadlineEvents: null,

      last_login: null,
      log_man: null,
      today_contests: null,
      new_events: null,
      bbs: null,
      event_comment: null,
      result_comment: null,
      ev_done_comment: null,
      wiki: null,
      participants: null,

      days: null,

      order: 'date',
      orders: [
        { value: 'date', name: '開催日' },
        { value: 'deadline_day', name: '締切日' },
        { value: 'created_at', name: '追加日' },
        { value: 'last_comment_date', name: '最終書込' },
        { value: 'registerd', name: '登録した' },
      ],
      eventList: null,
    };
  },
  computed: {
    sortedEventList() {
      return _.sortBy(this.eventList, (e) => {
        if (this.order === 'date') return e.date;
        else if (this.order === 'deadline_day') {
          if (e.deadline_day >= 0) return e.deadline_day;
          else if (e.deadline_day < 0) return Infinity;
          return null;
        } else if (this.order === 'created_at') return -new Date(e.created_at).getTime();
        else if (this.order === 'last_comment_date') return -new Date(e.last_comment_date).getTime();
        else if (this.order === 'registerd') return [!(_.find(e.choices, { id: e.choice }) || {}).positive === true, !_.isString(e.date), e.date];
        return null;
      });
    },
    afterDeadlineEvents() {
      return _.filter(this.eventList, e => e.deadline_after);
    },
  },
  created() {
    this.fetch();
  },
  methods: {
    fetch(onlyNewMessage = false) {
      axios.get('/user/newly_message').then((res) => {
        _.each(res.data, (v, k) => {
          this[k] = v;
        });
      }).catch(this.$_makeOnFail('情報の取得に失敗しました'));
      if (onlyNewMessage) return;
      axios.get('/schedule/panel').then((res) => {
        this.days = _.map(res.data, day => ({
          year: day.year,
          month: day.mon,
          date: day.day,
          day: new Date(day.year, day.mon - 1, day.day).getDay(),
          info: day.info || {},
          events: day.event,
          items: _.map(day.item, (it) => {
            if (_.isUndefined(it.emphasis)) it.emphasis = {};
            return it;
          }),
        }));
      }).catch(this.$_makeOnFail('情報の取得に失敗しました'));
      axios.get('/event/list').then((res) => {
        this.eventList = res.data;
        // computedにすると選択した瞬間に消える
        this.nearDeadlineEvents =
          _.filter(this.eventList, e => !e.forbidden && e.choice === null && _.inRange(e.deadline_day, 0, 11));
      }).catch(this.$_makeOnFail('情報の取得に失敗しました'));
    },
    relogin() {
      axios.post('/user/relogin').then(() => this.fetch(true));
    },
    formatDate(date) {
      if (date === null) return 'なし';
      const d = new Date(date);
      const year = d.getFullYear();
      const dateData = _.mapValues({
        year,
        month: d.getMonth() + 1,
        date: d.getDate(),
        day: $.util.weekday_ja[d.getDay()],
      }, v => `<strong>${v}</strong>`);
      if (year === new Date().getFullYear()) {
        return `${dateData.month}月${dateData.date}日(${dateData.day})`;
      }
      return `${dateData.year}年${dateData.month}月${dateData.date}日(${dateData.day})`;
    },
    select(event, choice) {
      event.choice = choice.id;
      axios.put(`/event/choose/${choice.id}`).catch(this.$_makeOnFail('更新に失敗しました'));
    },
  },
};
</script>
<style lang="scss" scoped>
#container {
  width: 100%;
  max-width: 860px;
}

.daily-photo {
  background-color: #dcffd3;
}
</style>
