<template>
  <div class="wrapper">
    <div class="day small border-top p-1 p-sm-2" :class="classes">
      <div style="line-height: 1.6em;">
        <span v-if="!day.today" class="date font-weight-bold">{{ showMore ? `${day.month}/` : '' }}{{ day.date }}</span>
        <b-badge v-else pill variant="primary" class="date">{{ showMore ? `${day.month}/` : '' }}{{ day.date }}</b-badge>
        <span v-if="showMore" class="font-weight-bold">({{ weekdays_ja[day.day] }})</span>
        <div class="d-block d-sm-none w-100"/>
        <span v-for="n in day.info.names" :key="n" class="text-muted">
          {{ n }}
        </span>
      </div>
      <template v-for="e in day.events">
        <div v-show="!copying" :key="e.id" class="mt-1">
          {{ e.name }}
        </div>
      </template>
      <template v-for="it in day.items">
        <div :key="it.id" class="dayitem mt-1" :class="{ selected: it.id === selected.id, 'cursor-pointer': copying }" @click="select($event, it)">
          <span>{{ it.name }}</span>
          <span v-if="it.emphasis.place" class="place">@{{ it.place }}</span>
          <span v-if="it.emphasis.start_at && it.emphasis.end_at" class="hourmin">&isin;{{ it.start_at }} &sim; {{ it.end_at }}</span>
          <span v-else-if="it.emphasis.start_at" class="hourmin">&isin;{{ it.start_at }} &sim;</span>
          <span v-else-if="it.emphasis.end_at" class="hourmin">&isin;&sim; {{ it.end_at }}</span>
          <span v-if="it.description" class="info-icon" data-toggle="tooltip" data-boundary="viewport" :title="it.description"/>
        </div>
      </template>
      <template v-if="copying">
        <div v-for="it in pastedItems" :key="it.id" class="dayitem cursor-pointer mt-1" :class="{ selected: it.id === selected.id }" @click.stop="remove($event, it)">
          <span>{{ it.name }}</span>
          <span v-if="it.emphasis.place" class="place">@{{ it.place }}</span>
          <span v-if="it.emphasis.start_at && it.emphasis.end_at" class="hourmin">&isin;{{ it.start_at }} &sim; {{ it.end_at }}</span>
          <span v-else-if="it.emphasis.start_at" class="hourmin">&isin;{{ it.start_at }} &sim;</span>
          <span v-else-if="it.emphasis.end_at" class="hourmin">&isin;&sim; {{ it.end_at }}</span>
          <span v-if="it.description" class="info-icon" data-toggle="tooltip" data-boundary="viewport" :title="it.description"/>
        </div>
      </template>
    </div>
  </div>
</template>
<script>
export default {
  props: {
    day: {
      type: Object,
      required: true,
    },
    showMore: {
      type: Boolean,
      default: false,
    },
    copying: {
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
  },
  data() {
    return {
      weekdays_ja: '日月火水木金土',
    };
  },
  computed: {
    classes() {
      return {
        holiday: this.day.day === 0 || this.day.info.is_holiday,
        saturday: this.day.day === 6 && !this.day.info.is_holiday,
        quiet: !this.showMore && !this.day.toman,
        'border-right': this.day.day !== 6,
        copying: this.copying,
        'cursor-pointer': !this.copying,
      };
    },
  },
  methods: {
    select(e, item) {
      if (!this.copying) return;
      e.stopPropagation();
      this.$emit('select', item);
    },
    remove(e, item) {
      this.$emit('remove', {
        day: this.day,
        item,
      });
    },
  },
};
</script>
<style lang="scss" scoped>
@import '../../assets/scss/helpers';

.wrapper {
  position: relative;
  &::before {
    display: block;
    padding-top: 100%;
    @include media-breakpoint-down(xs) {
      padding-top: 200%;
    }
    @media screen and (max-width: 375px) {
      padding-top: 250%;
    }
    content: '';
  }
}
.day {
  line-height: 1;
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  overflow-y: auto;
  background-color: #ffd;
  -webkit-overflow-scrolling: touch;
  @include media-breakpoint-down(md) {
    overflow-x: hidden;
    white-space: nowrap;
  }

  &:not(.copying):hover {
    background-color: #ffff91;
  }
  &.copying .dayitem {
    border: 1px dotted gray;
    border-radius: .25rem;
    &:hover, &.selected {
      background-color: #ffff91;
    }
  }
  &.quiet {
    background-color: $light !important;
    opacity: .8;
    .date {
      color: $secondary;
    }
    &:hover {
      background-color: #efefef !important;
    }
  }
  &.holiday {
    background-color: #ffe6e6;
    &:not(.copying):hover, &.copying .dayitem:hover, &.copying .dayitem.selected {
      background-color: #ffdcdc;
    }
  }
  &.saturday {
    background-color: #e9f8ff;
    &:not(.copying):hover, &.copying .dayitem:hover, &.copying .dayitem.selected {
      background-color: #bfdcff;
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
