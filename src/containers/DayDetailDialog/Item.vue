<template>
  <div v-if="isAuthenticated || item.public">
    <div class="d-flex">
      <div v-show="!editing">
        <h6 class="mb-1">
          <span :class="{ emph: item.emphasis.name }">{{ item.name }}</span>
          <span v-if="item.place" class="place" :class="{ emph: item.emphasis.place }">@{{ item.place }}</span>
        </h6>
        <div class="ml-1 text-muted" v-html="timeRange(item.start_at, item.end_at, item.emphasis.start_at, item.emphasis.end_at)"/>
        <b-alert v-if="item.description" variant="secondary" show class="small mt-1 px-3 py-2">
          {{ item.description }}
        </b-alert>
      </div>
      <div v-if="item.editable" class="ml-auto">
        <b-button variant="outline-success" @click="editing = !editing">
          {{ editing ? 'キャンセル' : '編集' }}
        </b-button>
      </div>
    </div>
    <day-item-form v-if="item.editable" v-show="editing" v-model="editItem">
      <template #default="{ form }">
        <b-button variant="danger" @click="removeItem">削除</b-button>
        <b-button variant="success" class="ml-2" @click="saveItem(form)">保存</b-button>
      </template>
    </day-item-form>
    <hr>
  </div>
</template>
<script>
import { cloneDeep } from 'lodash';
import { timeRange } from '@/utils';
import DayItemForm from './DayItemForm.vue';

export default {
  components: {
    DayItemForm,
  },
  props: {
    item: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      timeRange,
      editing: false,
      editItem: undefined,
    };
  },
  watch: {
    editing(newVal) {
      if (newVal) {
        this.editItem = cloneDeep(this.item);
      }
    },
  },
  methods: {
    saveItem(form) {
      if (!form.validate()) return;
      this.$http.put(`/schedule/detail/item/${this.item.id}`, this.editItem).then(() => {
        form.reset();
        this.editing = false;
        this.$emit('done');
      });
    },
    removeItem() {
      this.$http.delete(`/schedule/detail/item/${this.item.id}`).then(() => {
        this.$emit('done');
      });
    },
  },
};
</script>
<style lang="scss" scoped>
.place {
  color: #060;
}
.emph {
  text-decoration: underline;
  font-weight: bold;
}
</style>
