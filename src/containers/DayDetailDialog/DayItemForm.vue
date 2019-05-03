<template>
  <v-form ref="form" class="mt-3" @input.native="$emit('input', item)">
    <b-form-row class="align-items-center">
      <b-col cols="9" sm="6">
        <v-input v-model="item.name" placeholder="タイトル" required/>
      </b-col>
      <b-col>
        <b-checkbox v-model="item.emphasis.name">強調</b-checkbox>
      </b-col>
      <div class="d-block d-sm-none w-100 mt-3"/>
      <b-col cols="6" sm="2" class="mr-2">
        <b-select v-model="item.kind" :options="kinds"/>
      </b-col>
      <b-checkbox v-model="item.public" class="ml-auto mr-2">公開</b-checkbox>
    </b-form-row>
    <b-form-row class="align-items-center mt-3">
      <b-col cols="9">
        <v-input v-model="item.place" placeholder="場所"></v-input>
      </b-col>
      <b-col cols="3">
        <b-checkbox v-model="item.emphasis.place">強調</b-checkbox>
      </b-col>
    </b-form-row>
    <b-form-row class="align-items-center mt-3">
      <b-col cols="6" sm="3" lg="2">
        <v-field label="開始時刻">
          <v-input v-model="item.start_at" type="time" placeholder="hh:mm"/>
        </v-field>
      </b-col>
      <b-col cols="6" sm="3">
        <b-checkbox v-model="item.emphasis.start_at">強調</b-checkbox>
      </b-col>
      <b-col cols="6" sm="3" lg="2">
        <v-field label="終了時刻">
          <v-input v-model="item.end_at" type="time" placeholder="hh:mm"/>
        </v-field>
      </b-col>
      <b-col cols="6" sm="3">
        <b-checkbox v-model="item.emphasis.end_at">強調</b-checkbox>
      </b-col>
    </b-form-row>
    <v-textarea v-model="item.description" class="mt-3" placeholder="備考"/>
    <div class="d-flex justify-content-end mt-3">
      <slot :form="$refs.form"/>
    </div>
  </v-form>
</template>
<script>
import { VForm } from '@/components';

export default {
  components: {
    VForm,
  },
  model: {
    prop: 'item',
  },
  props: {
    item: {
      type: Object,
      default: () => ({ kind: 'practice', emphasis: {} }),
    },
  },
  computed: {
    kinds() {
      return [
        { value: 'practice', text: '練習' },
        { value: 'party', text: 'コンパ' },
        { value: 'etc', text: 'その他' },
      ];
    },
  },
};
</script>
