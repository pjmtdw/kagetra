<template>
  <div v-if="type" id="dialog" ref="dialog" class="modal fade" tabindex="-1" role="dialog" @keydown.enter="ok(true)" @keydown.shift.enter="ok(false)">
    <div class="modal-dialog modal-dialog-centered modal-sm" role="document">
      <div class="modal-content bg-light shadow-lg">
        <div class="modal-header">
          <h5 class="modal-title">{{ title }}</h5>
        </div>
        <div class="modal-body">
          <p v-if="type === 'confirm'">{{ message }}</p>
          <form v-else-if="type === 'input'" ref="form" novalidate @submit.prevent>
            <input ref="input" v-model="input" type="text" class="form-control" required placeholder="(Shift+Enterで確定)">
            <div class="invalid-feedback">入力してください</div>
          </form>
        </div>
        <div class="modal-footer">
          <button type="button" class="btn btn-outline-secondary" data-dismiss="modal" @click="result = false">キャンセル</button>
          <button type="button" class="btn btn-danger btn-ok" data-dismiss="modal" @click="result = true">OK</button>
        </div>
      </div>
    </div>
  </div>
</template>
<script>
export default {
  data() {
    return {
      type: null,
      title: '',
      message: '',
      input: null,
      $dialog: null,
      def: null,      // 閉じた後にresolve or rejectされる
      result: null,   // ok: true, cancel: false
    };
  },
  methods: {
    init(func) {
      this.result = null;
      this.def = new $.Deferred();
      this.$nextTick(() => {
        // dataの生成段階ではまだDOMが生成されてないのでここで初期化
        this.$dialog = $(this.$refs.dialog);
        if (func) func();
        this.$dialog.modal('show');
        this.$dialog.on('hidden.bs.modal', () => {
          if (this.result) this.def.resolve(this.input);
          else this.def.reject();
          this.type = null;
          this.$dialog = null;
        });
      });
      return this.def.promise();
    },
    confirm(title, message) {
      this.type = 'confirm';
      this.title = message === undefined ? '確認' : title;
      this.message = message === undefined ? title : message;
      return this.init();
    },
    prompt(title) {
      this.type = 'input';
      this.title = title;
      this.input = null;
      return this.init(() => {
        this.$dialog.on('shown.bs.modal', () => {
          this.$refs.input.focus();
        });
        this.$dialog.on('hide.bs.modal', (e) => {
          if (!this.result || $(this.$refs.form).check()) return;
          this.result = false;
          e.preventDefault();
        });
      });
    },
    ok(strict) {
      // 誤入力防止の為enterはconfirmのみ
      if (strict && this.type !== 'confirm') return;
      this.result = true;
      this.$dialog.modal('hide');
    },
  },
};
</script>
<style lang="scss" scoped>
#dialog {
  z-index: 1100;
}
</style>
