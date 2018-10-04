<template>
  <main id="container" class="mx-auto">
    <!-- nav -->
    <div class="d-flex flex-row align-items-center mt-3 mb-2">
      <ul class="pagination my-2 justify-content-center">
        <li class="page-item" data-toggle="tooltip" :title="`${prev.year}年${prev.month}月`">
          <router-link class="page-link" :to="`/${prev.year}-${prev.month}`">&laquo;</router-link>
        </li>
        <li class="page-item active" data-toggle="tooltip">
          <span class="page-link" @click="editMonth">
            {{ year }}年{{ month }}月
          </span>
        </li>
        <li class="page-item" data-toggle="tooltip" :title="`${next.year}年${next.month}月`">
          <router-link class="page-link" :to="`/${next.year}-${next.month}`">&raquo;</router-link>
        </li>
      </ul>
      <div class="ml-auto">
        <router-link v-show="!gIsPublic && !bulkEditing && !holidayEditing" class="btn btn-sm btn-info" to="/past_event">過去の行事</router-link>
      </div>
      <div v-if="!gIsPublic" class="ml-2" :class="!bulkEditing && !holidayEditing ? ['btn-group', 'btn-group-sm'] : ''">
        <button v-show="!bulkEditing && !holidayEditing" class="btn btn-success" @click="bulkEditing = true">
          一括追加
        </button>
        <button v-show="!bulkEditing && !holidayEditing" class="btn btn-success" @click="holidayEditing = true">
          祝日編集
        </button>
        <span v-show="bulkEditing" class="help-icon" data-toggle="tooltip" data-placement="bottom" data-html="true" title="<div class=&quot;text-left&quot;>(1) コピー元の予定を選択(前の月でも可)<br>(2) 予定をコピーしたい日をクリック<br>(3) 保存ボタンを押す</div>"/>
        <button v-show="bulkEditing" class="btn btn-sm btn-success" @click="bulkEditing = false">キャンセル</button>
        <button v-show="bulkEditing" class="btn btn-sm btn-success" @click="save">保存</button>
        <span v-show="holidayEditing" class="help-icon" data-toggle="tooltip" data-placement="bottom" title="祝日は一行に一つ入れて下さい"/>
        <button v-show="holidayEditing" class="btn btn-sm btn-success" @click="holidayEditing = false">キャンセル</button>
        <button v-show="holidayEditing" class="btn btn-sm btn-success" @click="updateHoliday">保存</button>
      </div>
    </div>
    <!-- カレンダー -->
    <div v-if="!mobile" class="container">
      <div class="row">
        <div class="col font-weight-bold text-danger">日</div>
        <div class="col font-weight-bold">月</div>
        <div class="col font-weight-bold">火</div>
        <div class="col font-weight-bold">水</div>
        <div class="col font-weight-bold">木</div>
        <div class="col font-weight-bold">金</div>
        <div class="col font-weight-bold text-primary">土</div>
      </div>
      <div v-for="(week, i) in weeks" :key="`${year}-${month}-w${i}`" class="row">
        <div v-for="day in week" :key="`${year}-${month}-${day.date}`" class="col p-1">
          <ScheduleItem ref="sItem" :day="day" :bulk-editing="bulkEditing" :holiday-editing="holidayEditing" :selected="selected" :pasted-items="pasted[day.date]"
                        @click.native="openDetail(day)" @select="selected = $event" @remove="remove"/>
        </div>
      </div>
    </div>
    <!-- カレンダー(mobile) -->
    <div v-else class="d-flex flex-row flex-wrap">
      <div v-for="(day, i) in days" :key="`${year}-${month}-${day.date}`" class="col-3 py-1 pr-0" :class="i % 4 === 0 ? 'pl-0' : 'pl-1'">
        <ScheduleItem ref="sItem" :mobile="true" :day="day" :bulk-editing="bulkEditing" :holiday-editing="holidayEditing" :selected="selected" :pasted-items="pasted[day.date]"
                      @click.native="openDetail(day)" @select="selected = $event" @remove="remove"/>
      </div>
    </div>

    <!-- dialog -->
    <DayDetailDialog ref="detailDialog" @close="fetch" @openinfo="openInfo" @opencomment="openComment"/>
    <EventInfoDialog ref="infoDialog" @close="fetch" @openedit="openEdit" @opencomment="openComment"/>
    <EventEditDialog ref="editDialog" @close="fetch"/>
    <EventCommentDialog ref="commentDialog" @close="fetch" @openinfo="openInfo"/>
  </main>
</template>
<script>
import ScheduleItem from './subcomponents/ScheduleItem.vue';
import DayDetailDialog from './subcomponents/DayDetailDialog.vue';
import EventInfoDialog from './subcomponents/EventInfoDialog.vue';
import EventEditDialog from './subcomponents/EventEditDialog.vue';
import EventCommentDialog from './subcomponents/EventCommentDialog.vue';

export default {
  components: {
    ScheduleItem,
    DayDetailDialog,
    EventInfoDialog,
    EventEditDialog,
    EventCommentDialog,
  },
  props: {
    year: {
      type: [String, Number],
      default: new Date().getFullYear(),
    },
    month: {
      type: [String, Number],
      default: new Date().getMonth() + 1,
    },
  },
  data() {
    return {
      mobile: window.innerWidth < $.util.breakpoints.md,
      weekday_ja: $.util.weekday_ja,
      today: null,
      month_day: null,
      before_day: null,
      after_day: null,
      day_infos: null,
      events: null,
      items: null,
      // 一括追加
      bulkEditing: false,
      selected: {},
      pasted: {},
      // 祝日編集
      holidayEditing: false,
    };
  },
  computed: {
    isCurrentMonth() {
      const date = new Date();
      return date.getFullYear() === Number(this.year) && date.getMonth() + 1 === Number(this.month);
    },
    days() {
      if (this.month_day === null) return null;
      const days = [];
      let day = this.before_day;
      _.each(_.range(1, this.month_day + 1), (d) => {
        days.push({
          date: d,
          day,
          today: this.isCurrentMonth && this.today === d,
          info: this.day_infos[d] || {},
          events: this.events[d],
          items: this.items[d],
        });
        day += 1;
        if (day === 7) day = 0;
      });
      return days;
    },
    weeks() {
      if (this.month_day === null) return null;
      const weeks = [];
      const beforeDays = _.map(_.range(-this.before_day + 1, 1), v => ({ date: v }));
      let week = beforeDays;
      _.each(_.range(1, this.month_day + 1), (d) => {
        week.push({
          date: d,
          day: week.length,
          today: this.isCurrentMonth && this.today === d,
          info: this.day_infos[d] || {},
          events: this.events[d],
          items: this.items[d],
        });
        if (week.length === 7) {
          weeks.push(week);
          week = [];
        }
      });
      const afterDays = _.map(_.range(this.month_day + 1, this.month_day + this.after_day + 1), v => ({ date: v }));
      weeks.push(_.concat(week, afterDays));
      return weeks;
    },
    prev() {
      return _.toNumber(this.month) === 1 ? {
        year: this.year - 1,
        month: 12,
      } : {
        year: this.year,
        month: this.month - 1,
      };
    },
    next() {
      return _.toNumber(this.month) === 12 ? {
        year: _.toNumber(this.year) + 1,
        month: 1,
      } : {
        year: this.year,
        month: _.toNumber(this.month) + 1,
      };
    },
  },
  watch: {
    year() {
      this.holidayEditing = false;
      this.fetch();
    },
    month() {
      this.holidayEditing = false;
      this.fetch();
    },
    bulkEditing(v) {
      if (v) {
        this.selected = {};
        this.pasted = {};
      }
    },
  },
  created() {
    this.fetch();
    window.addEventListener('resize', () => {
      this.mobile = window.innerWidth < $.util.breakpoints.md;
    });
  },
  mounted() {
    $('[data-toggle="tooltip"]').tooltip();
  },
  updated() {
    $('[data-toggle="tooltip"]').tooltip('dispose');
    $('[data-toggle="tooltip"]').tooltip();
  },
  methods: {
    fetch() {
      axios.get(`/schedule/cal/${this.year}-${this.month}`).then((res) => {
        this.today = res.data.today;
        this.month_day = res.data.month_day;
        this.before_day = res.data.before_day;
        this.after_day = res.data.after_day;
        this.day_infos = res.data.day_infos;
        this.events = res.data.events;
        this.items = _.mapValues(res.data.items, (dayItems) => {
          /* eslint-disable-next-line no-param-reassign */
          dayItems = _.map(dayItems, (it) => {
            if (_.isUndefined(it.emphasis)) {
              it.emphasis = {};
            } else {
              const em = {};
              _.each(it.emphasis, (e) => {
                em[e] = true;
              });
              it.emphasis = em;
            }
            return it;
          });
          return dayItems;
        });
      });
    },
    editMonth() {
      this.$_prompt('年と月を入力', `${this.year}-${this.month}`).then((res) => {
        if (res.match(/^\d+-(0?[1-9]|1[1-2])$/) !== null) this.$router.push(`/${res}`);
        else this.$_notify('warning', '形式が正しくありません');
      });
    },
    // 一括追加
    paste(day) {
      if (!_.isEmpty(this.selected)) {
        if (!_.includes(day.items, this.selected) && !_.includes(this.pasted[day.date], this.selected)) {
          if (_.isUndefined(this.pasted[day.date])) this.$set(this.pasted, day.date, []);
          this.pasted[day.date].push(this.selected);
        }
      }
    },
    remove(data) {
      this.$delete(this.pasted[data.day.date], _.indexOf(this.pasted[data.day.date], data.item));
    },
    save() {
      const data = _.mapKeys(_.mapValues(this.pasted, v => _.map(v, it => it.id)), (v, k) => `${this.year}-${this.month}-${k}`);
      axios.post('/schedule/copy', data).then(() => {
        this.bulkEditing = false;
      }).catch(() => {
        this.$_notify('danger', '更新に失敗しました');
      });
    },
    // 祝日編集
    updateHoliday() {
      const data = {};
      _.each(this.$refs.sItem, (si) => {
        const e = si.getEditHoliday();
        if (!_.isUndefined(e)) data[`${this.year}-${this.month}-${e.date}`] = e.data;
      });
      axios.post('/schedule/update_holiday', data).then(() => {
        this.holidayEditing = false;
        this.fetch();
      }).catch(() => {
        this.$_notify('danger', '更新に失敗しました');
      });
    },
    // open modal
    openDetail(day) {
      if (this.bulkEditing) {
        this.paste(day);
        return;
      }
      if (this.holidayEditing) return;
      this.$refs.detailDialog.open(this.year, this.month, day);
    },
    openInfo(eventId) {
      this.$refs.infoDialog.open(eventId);
    },
    openComment(eventId) {
      this.$refs.commentDialog.open(eventId);
    },
    openEdit(data) {
      this.$refs.editDialog.open(data);
    },
  },
};
</script>
<style lang="scss" scoped>
#container {
  width: 100%;
  max-width: 860px;
}

.modal-body hr:last-child {
  display: none;
}

.place {
  color: #060;
}
.hourmin {
  color: #600;
}
</style>
