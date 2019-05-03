<template>
  <div v-if="loaded" class="container px-0 pt-3 pb-5">
    <!-- nav -->
    <div v-if="screenFrom('sm')" class="d-flex justify-content-between align-items-center position-relative">
      <slot/>
      <template v-if="isAuthenticated">
        <b-button v-if="!copying" variant="success" size="sm" @click="copying = true">
          <v-icon name="pen" size="sm"/>
          予定コピー
        </b-button>
        <div v-else>
          <v-help>
            <div class="text-left" v-html="helpMessage"/>
          </v-help>
          <b-button variant="success ml-1" size="sm" @click="copying = false">キャンセル</b-button>
          <b-button variant="success ml-1" size="sm" @click="save">保存</b-button>
        </div>
      </template>
      <div class="position-absolute d-flex justify-content-center w-100 pe-none">
        <nav-button-group :links="links" class="pe-auto"/>
      </div>
    </div>
    <template v-else>
      <div class="d-flex justify-content-center">
        <nav-button-group :links="links"/>
      </div>
      <floating-button v-if="isAuthenticated" :icon="fabIcon" :tip="copying ? helpMessage : null" :buttons="editButtons" :no-hide="copying"/>
    </template>
    <!-- calendar -->
    <b-container class="bg-white rounded border shadow-sm mt-2">
      <b-row :class="{ small: screenUntil('xs') }">
        <b-col class="text-danger text-center">日</b-col>
        <b-col class="text-center">月</b-col>
        <b-col class="text-center">火</b-col>
        <b-col class="text-center">水</b-col>
        <b-col class="text-center">木</b-col>
        <b-col class="text-center">金</b-col>
        <b-col class="text-primary text-center">土</b-col>
      </b-row>
      <b-row v-for="(week, i) in weeks" :key="`${year}-${month}-w${i}`">
        <b-col v-for="day in week" :key="`${year}-${month}-${day.date}`" class="px-0">
          <ScheduleItem ref="sItem" :day="day" :copying="copying" :selected="selected" :pasted-items="pasted[day]"
                        @click.native="onClick(day)" @select="selected = $event" @remove="remove"/>
        </b-col>
      </b-row>
    </b-container>
  </div>
</template>
<script>
import { isEmpty, mapKeys, mapValues } from 'lodash';
import { createVueInstance } from '@/utils';
import { FloatingButton, NavButtonGroup } from '@/components';
import { DayDetailDialog } from '@/containers';
import ScheduleItem from './ScheduleItem.vue';

export default {
  components: {
    FloatingButton,
    NavButtonGroup,
    ScheduleItem,
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
      loaded: false,
      weeks: null,

      // 予定コピー
      fabIcon: (isActive) => {
        if (this.copying) return isActive ? 'angle-double-down' : 'angle-double-up';
        return isActive ? 'times' : 'pen';
      },
      helpMessage: `
        (1) コピー元の予定を選択(他の月でも可)<br>
        (2) 予定をコピーしたい日をクリック<br>
        (3) 保存ボタンを押す`,
      copying: false,
      selected: {},
      pasted: {},
    };
  },
  computed: {
    editButtons() {
      if (this.copying) {
        return [
          { icon: 'ban', text: 'キャンセル', onClick: () => { this.copying = false; return false; } },
          { icon: 'save', text: '保存', onClick: () => { this.save(); return false; } },
        ];
      }
      return [
        { icon: 'copy', text: '予定コピー', onClick: () => { this.copying = true; } },
      ];
    },
    prev() {
      return Number(this.month) === 1 ? {
        year: this.year - 1,
        month: 12,
      } : {
        year: this.year,
        month: this.month - 1,
      };
    },
    next() {
      return Number(this.month) === 12 ? {
        year: Number(this.year) + 1,
        month: 1,
      } : {
        year: this.year,
        month: Number(this.month) + 1,
      };
    },
    links() {
      return [
        { text: '«', to: `/${this.prev.year}-${this.prev.month}`, tooltip: `${this.prev.year}年${this.prev.month}月` },
        { text: `${this.year}年${this.month}月`, active: true, onClick: this.editMonth },
        { text: '»', to: `/${this.next.year}-${this.next.month}`, tooltip: `${this.next.year}年${this.next.month}月` },
      ];
    },
  },
  watch: {
    year() {
      this.fetch();
    },
    month() {
      this.fetch();
    },
    copying(v) {
      if (v) {
        this.selected = {};
        this.pasted = {};
      }
    },
  },
  created() {
    this.fetch();
  },
  methods: {
    fetch() {
      this.$http.get(`/schedule/cal/${this.year}-${this.month}`).then(({ data }) => {
        this.weeks = data;
        this.weeks.forEach((week) => {
          week.forEach((day) => {
            day.dateObj = new Date(day.year, day.month - 1, day.date);
            day.toString = () => String(day.dateObj);
          });
        });
        this.loaded = true;
      });
    },
    editMonth() {
      this.$prompt('年と月を入力', { value: `${this.year}-${this.month}`, placeholder: 'yyyy-M' }).then((res) => {
        if (res.match(/^\d+-(0?[1-9]|1[1-2])$/) !== null) this.$router.push(`/${res}`);
        else this.$message.warn('形式が正しくありません');
      });
    },
    onClick(day) {
      if (this.copying) {
        this.paste(day);
      } else {
        createVueInstance(DayDetailDialog).open(day).$on('update', this.fetch);
      }
    },
    // 一括追加
    paste(day) {
      if (!isEmpty(this.selected)) {
        if (!day.items.includes(this.selected) && !(this.pasted[day] || []).includes(this.selected)) {
          if (!this.pasted[day]) this.$set(this.pasted, day, []);
          this.pasted[day].push(this.selected);
        }
      }
    },
    remove({ day, item }) {
      this.$delete(this.pasted[day], this.pasted[day].indexOf(item));
    },
    save() {
      const data = mapKeys(
        mapValues(this.pasted, items => items.map(item => item.id)),
        (v, date) => {
          const d = new Date(date);
          return `${d.getFullYear()}-${d.getMonth() + 1}-${d.getDate()}`;
        }
      );
      this.$http.post('/schedule/copy', data).then(() => {
        this.copying = false;
        this.fetch();
      });
    },
  },
};
</script>
<style lang="scss" scoped>
</style>
