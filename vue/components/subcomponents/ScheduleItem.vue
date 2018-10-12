<template>
  <div v-if="isInvalid" class="day bg-light border-dotted rounded"/>
  <div v-else class="day small rounded p-2"
       :class="{ holiday: day.day === 0 || day.info.is_holiday, saturday: day.day === 6 && !day.info.is_holiday, bulkedit: bulkEditing, 'cursor-pointer': !bulkEditing && !holidayEditing,
                 today: day.today, 'border-dotted': !day.today }">
    <div>
      <span class="font-weight-bold">{{ showMore ? `${day.month}/` : '' }}{{ day.date }}</span>
      <span v-if="mobile || showMore" class="font-weight-bold">({{ weekday_ja[day.day] }})</span>
      <div class="d-block d-sm-none w-100"/>
      <template v-if="!holidayEditing">
        <span v-for="n in day.info.names" class="text-muted">
          {{ n }}
        </span>
      </template>
      <label v-else class="mb-0">
        <input v-model="editHoliday.is_holiday" type="checkbox">
        祝日
      </label>
    </div>
    <template v-for="e in day.events">
      <div v-if="!gIsPublic || e.public" v-show="!bulkEditing && !holidayEditing" class="mt-1">
        {{ e.name }}
      </div>
    </template>
    <template v-for="it in day.items">
      <div v-if="!gIsPublic || it.public" v-show="!holidayEditing" :key="it.id" class="dayitem mt-1" :class="{ selected: it.id === selected.id, 'cursor-pointer': bulkEditing }" @click="select($event, it)">
        <span>{{ it.name }}</span>
        <span v-if="it.emphasis.place" class="place">@{{ it.place }}</span>
        <span v-if="it.emphasis.start_at && it.emphasis.end_at" class="hourmin">&isin;{{ it.start_at }} &sim; {{ it.end_at }}</span>
        <span v-else-if="it.emphasis.start_at" class="hourmin">&isin;{{ it.start_at }} &sim;</span>
        <span v-else-if="it.emphasis.end_at" class="hourmin">&isin;&sim; {{ it.end_at }}</span>
        <span v-if="it.description" class="info-icon" data-toggle="tooltip" :title="it.description"/>
      </div>
    </template>
    <template v-if="bulkEditing">
      <div v-for="it in pastedItems" :key="it.id" class="dayitem cursor-pointer mt-1" :class="{ selected: it.id === selected.id }" @click.stop="remove($event, it)">
        <span>{{ it.name }}</span>
        <span v-if="it.emphasis.place" class="place">@{{ it.place }}</span>
        <span v-if="it.emphasis.start_at && it.emphasis.end_at" class="hourmin">&isin;{{ it.start_at }} &sim; {{ it.end_at }}</span>
        <span v-else-if="it.emphasis.start_at" class="hourmin">&isin;{{ it.start_at }} &sim;</span>
        <span v-else-if="it.emphasis.end_at" class="hourmin">&isin;&sim; {{ it.end_at }}</span>
        <span v-if="it.description" class="info-icon" data-toggle="tooltip" :title="it.description"/>
      </div>
    </template>
    <textarea v-if="holidayEditing" v-model="editHoliday.names" class="form-control mt-1 p-0" rows="4"/>
  </div>
</template>
<script>
export default {
  props: {
    mobile: {
      type: Boolean,
      default: false,
    },
    day: {
      type: Object,
      required: true,
    },
    showMore: {
      type: Boolean,
      default: false,
    },
    bulkEditing: {
      type: Boolean,
      default: false,
    },
    selected: {
      type: Object,
      default() {
        return {};
      },
    },
    pastedItems: {
      type: Array,
      default: null,
    },
    holidayEditing: {
      type: Boolean,
      default: false,
    },
  },
  data() {
    return {
      weekday_ja: $.util.weekday_ja,
      editHoliday: null,
    };
  },
  computed: {
    isInvalid() {
      return _.isUndefined(this.day.day);
    },
  },
  watch: {
    holidayEditing(v) {
      if (this.isInvalid) return;
      if (v) {
        this.editHoliday = {
          names: _.join(this.day.info.names, '\n'),
          is_holiday: this.day.info.is_holiday,
        };
      }
    },
  },
  methods: {
    select(e, item) {
      if (!this.bulkEditing) return;
      e.stopPropagation();
      this.$emit('select', item);
    },
    remove(e, item) {
      this.$emit('remove', {
        day: this.day,
        item,
      });
    },
    getEditHoliday() {
      if (this.isInvalid) return undefined;
      if (_.join(this.day.info.names, '\n') !== this.editHoliday.names ||
        this.day.info.is_holiday !== this.editHoliday.is_holiday) {
        return {
          date: this.day.date,
          data: {
            names: _.split(this.editHoliday.names, '\n'),
            holiday: this.editHoliday.is_holiday,
          },
        };
      }
      return undefined;
    },
  },
};
</script>
<style lang="scss" scoped>
.day {
  line-height: 1;
  height: 10rem;
  background-color: #ffd;
  overflow-y: auto;

  &:not(.bulkedit):hover {
    background-color: #ffff91;
  }
  &.bulkedit .dayitem {
    border: 1px dotted gray;
    border-radius: .25rem;
    &:hover, &.selected {
      background-color: #ffff91;
    }
  }
  &.today {
    border: 2px solid green;
  }
  &.holiday {
    background-color: #fdd;
    &:not(.bulkedit):hover, &.bulkedit .dayitem:hover, &.bulkedit .dayitem.selected {
      background-color: #ff9191;
    }
  }
  &.saturday {
    background-color: #ddf;
    &:not(.bulkedit):hover, &.bulkedit .dayitem:hover, &.bulkedit .dayitem.selected {
      background-color: #9191ff;
    }
  }
}

.info-icon::before {
  top: 0;
}

textarea {
  font-size: 10px;
}
</style>
