<template>
  <div class="modal fade" tabindex="-1" role="dialog">
    <div class="modal-dialog modal-lg" role="document">
      <div class="modal-content">
        <div class="modal-header"></div>
        <div class="modal-body"></div>
      </div>
    </div>
  </div>
</template>
<script>
export default {
  data() {
    return {
      id: null,
    };
  },
  methods: {
    open(id) {
      this.id = id;
      const $dialog = $(this.$el);
      $dialog.modal('show');
      $dialog.on('hide.bs.modal', () => this.$emit('close'));
      this.fetch();
    },
    fetch() {

    },
  },
};
</script>
