export default {
  created() {
    document.body.appendChild(this.$mount().$el);
  },
  destroyed() {
    document.body.removeChild(this.$el);
  },
};
