<template>
  <b-modal v-if="detail" ref="dialog" size="lg" hide-footer>
    <template #modal-title>
      {{ detail.year }}年{{ detail.month }}月{{ detail.date }}日 (
        <span class="font-weight-bold">{{ weekdays_ja[detail.day] }}</span>
      )
      <span v-for="n in detail.info.names" :key="n" :class="{ 'text-danger': detail.info.is_holiday }">{{ n }}</span>
    </template>
    <template #default>
      <template v-for="e in detail.events">
        <event :key="e.id" :event="e"/>
        <!-- eslint-disable-next-line vue/require-v-for-key -->
        <hr>
      </template>
      <template v-for="item in detail.items">
        <item :key="item.id" :item="item" @done="fetch(); $emit('update')"/>
      </template>
      <template v-if="isAuthenticated">
        <div class="d-flex">
          <b-button class="ml-auto" :variant="editing ? 'outline-success' : 'success'" @click="editing = !editing">
            {{ editing ? 'キャンセル' : '予定追加' }}
          </b-button>
        </div>
        <b-collapse v-model="editing" id="new-item-form">
          <day-item-form v-model="newItem">
            <template #default="{ form }">
              <b-button variant="success" @click="addSchedule(form)">保存</b-button>
            </template>
          </day-item-form>
        </b-collapse>
      </template>
    </template>
  </b-modal>
</template>
<script>
import { DialogMixin, timeRange } from '@/utils';
import Event from './Event.vue';
import Item from './Item.vue';
import DayItemForm from './DayItemForm.vue';

export default {
  components: {
    Event,
    Item,
    DayItemForm,
  },
  mixins: [DialogMixin],
  data() {
    return {
      weekdays_ja: '日月火水木金土',
      timeRange,
      detail: null,

      // 予定追加
      editing: false,
      newItem: undefined,
    };
  },
  methods: {
    open(day) {
      this.detail = {
        year: day.year,
        month: day.month,
        day: day.day,
        date: day.date,
        info: day.info,
        events: [],
        items: [],
      };
      this.fetch();
      this.$nextTick(() => this.$refs.dialog.show());
      return this;
    },
    fetch() {
      this.$http.get(`/schedule/detail/${this.detail.year}-${this.detail.month}-${this.detail.date}`).then(({ data }) => {
        this.detail.events = data.events;
        this.detail.items = data.items.map((item) => {
          item.editing = false;
          return item;
        });
      });
    },
    // 追加
    addSchedule(form) {
      if (!form.validate()) return;
      const data = this.newItem;
      data.year = this.detail.year;
      data.mon = this.detail.month;
      data.day = this.detail.date;
      this.$http.post('/schedule/detail/item', data).then(() => {
        form.reset();
        this.editing = false;
        this.newItem = undefined;
        this.fetch();
        this.$emit('update');
      });
    },
  },
};
</script>
