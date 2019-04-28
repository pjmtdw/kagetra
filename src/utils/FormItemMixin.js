export default {
  data() {
    return {
      inputElement: null,
    };
  },
  computed: {
    // Find parent Field, max 3 levels deep.
    parentField() {
      let parent = this.$parent;
      for (let i = 0; i < 3; i++) {
        if (parent && parent.$vnode.componentOptions.tag === 'v-field') return parent;
        parent = parent.$parent;
      }
      return null;
    },
    statusType() {
      if (!this.parentField) return null;
      return this.parentField.statusType;
    },
  },
  mounted() {
    this.inputElement = this.$el;
    this.$nextTick(this.updateValidity);
  },
  methods: {
    updateValidity() {
      if (!this.parentField) return;
      if (this.inputElement.checkValidity()) {
        this.parentField.onValid();
      } else {
        this.parentField.onInvalid();
      }
    },
  },
};
