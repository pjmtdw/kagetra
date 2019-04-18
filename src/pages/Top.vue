<template>
  <div v-if="loaded" class="container">
    <div class="columns mt-2">
      <div class="column is-half">
        <div class="box">
          <span>最終ログイン: {{ last_login.last }}</span>
          <a v-if="last_login.can_relogin" href="#" @click="relogin">(+{{ last_login.from_last }}分)</a>
          <span v-else-if="last_login.from_last >= 5" class="has-text-grey-light">(+{{ last_login.from_last }}分)</span>
          <span>, 今月ログイン: {{ log_mon }}</span>
        </div>
      </div>
    </div>
  </div>
</template>
<script>
import _ from 'lodash';

export default {
  data() {
    return {
      loaded: false,

      last_login: null,
      log_mon: null,
    };
  },
  created() {
    this.fetch().then(() => {
      this.loaded = true;
    });
  },
  methods: {
    fetch(onlyNewMessage = false) {
      const p1 = this.$http.get('/user/newly_message').then((res) => {
        this.last_login = res.data.last_login;
        this.log_mon = res.data.log_mon;
      });
      if (onlyNewMessage) return p1;

      const p2 = this.$http.get('/schedule/panel').then((res) => {
        this.days = res.data.map(day => ({
          year: day.year,
          month: day.mon,
          date: day.day,
          day: new Date(day.year, day.mon - 1, day.day).getDay(),
          info: day.info || {},
          events: day.event,
          items: day.item.map((it) => {
            if (!it.emphasis) it.emphasis = {};
            return it;
          }),
        }));
      });

      const p3 = this.$http.get('/event/list').then((res) => {
        this.eventList = res.data;
        // computedにすると選択した瞬間に消える
        this.nearDeadlineEvents =
          this.eventList.filter(e => !e.forbidden && e.choice === null && _.inRange(e.deadline_day, 0, 11));
      });

      return Promise.all([p1, p2, p3]);
    },
    relogin() {
      this.$http.post('/user/relogin').then(() => this.fetch(true));
    },
  },
};
</script>
<style lang="scss" scoped>
.container {
  max-width: 90%;
}
</style>
