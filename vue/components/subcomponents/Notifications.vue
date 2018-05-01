<template>
  <div v-if="notifications.length" id="notifications" class="position-fixed fixed-top w-25">
    <div v-for="n in notifications" :key="n.id" :ref="`alert${n.id}`" class="alert alert-dismissible fade show shadow mt-1 mb-3" :class="`alert-${n.type}`" role="alert">
      {{ n.message }}
      <button class="close p-0" type="button" data-dismiss="alert" aria-label="Close">
        <span aria-hidden="true">&times;</span>
      </button>
    </div>
  </div>
</template>
<script>
export default {
  data() {
    return {
      count: 0,
      notifications: [],
    };
  },
  methods: {
    notify(_type, _message) {
      let type = _type;
      let message = _message;
      // typeは省略可
      if (message === undefined) {
        message = _type;
        type = 'success';
      }
      // クリア
      if (type === 'success') {
        this.notifications = _.filter(this.notifications, v => !_.includes(['danger', 'warning'], v.type));
      } else if (type === 'clear') {
        this.notifications = [];
      }

      const id = this.count;
      this.notifications.push({
        id,
        type,
        message,
      });
      this.count += 1;
      this.$nextTick(() => {
        // bootstrapのアニメーションが終わってから削除する
        $(this.$refs[`alert${id}`]).on('closed.bs.alert', () => {
          for (let i = 0; i < this.notifications.length; i++) {
            if (this.notifications[i].id === id) {
              this.notifications.splice(i, 1);
              break;
            }
          }
        });
      });

      // 10秒後に消える
      setTimeout(() => {
        $(this.$refs[`alert${id}`]).alert('close');
      }, 10 * 1000);
    },
  },
};
</script>
<style lang="scss" scoped>
#notifications {
  z-index: 1200;
  left: auto;
  right: 10px;
  min-width: 200px;
}
</style>
