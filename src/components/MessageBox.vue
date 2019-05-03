<template>
  <b-modal ref="modal" v-if="type === 'confirm'" :title="title" @hidden="settle" @keydown.enter.native="onOK">
    <span>{{ message }}</span>
    <template #modal-footer>
      <div class="d-flex justify-content-end">
        <b-button variant="outline-secondary" class="mr-1" @click="onCancel">キャンセル</b-button>
        <b-button :variant="variant" @click="onOK">OK</b-button>
      </div>
    </template>
  </b-modal>
  <b-modal ref="modal" v-else :title="title" @shown="$refs.input.focus(); $refs.input.select()" @keydown.shift.enter.native="onOK">
    <p v-if="message">{{ message }}</p>
    <v-field :label="label" feedback="入力が必要です">
      <v-input ref="input" v-model="value" :requried="required" :state="state" :placeholder="placeholder"/>
    </v-field>
    <template #modal-footer>
      <div class="d-flex justify-content-end">
        <b-button variant="outline-secondary" class="mr-1" @click="onCancel">キャンセル</b-button>
        <b-button :variant="variant" @click="onOK">OK</b-button>
      </div>
    </template>
  </b-modal>
</template>
<script>
import { DialogMixin } from '@/utils';

export default {
  mixins: [DialogMixin],
  data() {
    return {
      show: false,
      result: null,
      resolve: null,
      reject: null,

      type: null,
      title: null,
      variant: null,
      message: null,

      value: null,
      state: null,
      label: null,
      required: true,
      placeholder: null,
    };
  },
  watch: {
    value(newVal) {
      if (newVal && this.state === false) this.state = true;
      else if (!newVal && this.state === true) this.state = false;
    },
  },
  methods: {
    open(options) {
      this.type = options.type === 'prompt' ? 'prompt' : 'confirm';
      this.title = options.title || (this.type === 'confirm' ? '確認' : '入力');
      this.variant = options.variant || (this.type === 'confirm' ? 'danger' : 'primary');
      this.message = options.message;
      this.value = options.value;
      this.label = options.label;
      this.placeholder = options.placeholder;
      this.required = options.required !== false;
      this.$nextTick(() => {
        this.$refs.modal.show();
      });
      return new Promise((resolve, reject) => {
        this.resolve = resolve;
        this.reject = reject;
      });
    },
    onOK() {
      if (this.type === 'confirm') {
        this.result = true;
        this.$refs.modal.hide();
      } else if (this.type === 'prompt') {
        if (this.required && !this.input) {
          this.state = false;
        } else {
          this.result = true;
          this.$refs.modal.hide();
        }
      }
    },
    onCancel() {
      this.$refs.modal.hide();
    },
    settle() {
      if (this.result) {
        if (this.type === 'confirm') this.resolve();
        else this.resolve(this.value);
      } else {
        this.reject();
      }
      this.$destroy();
    },
  },
};
</script>
