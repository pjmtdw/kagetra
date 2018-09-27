<template>
  <div class="list-group list-group-flush">
    <div v-for="(item, i) in comments" :key="item.id" class="list-group-item bg-transparent" :class="itemClass">
      <div v-if="!item.editing" class="d-flex">
        <span class="name">{{ item.user_name }}</span>
        <span class="date">@{{ item.date }}</span>
        <h6 v-if="item.is_new" class="align-self-center"><span class="badge badge-info mx-1">New</span></h6>
        <button v-if="item.editable" class="btn btn-outline-success btn-sm ml-auto" @click="toggleEditItem(i, item.id)">
          編集
        </button>
      </div>
      <div v-show="!item.editing" class="pre mt-1 pl-2">{{ item.body }}</div>
      <form v-if="item.editable" v-show="item.editing" :ref="'editForm' + item.id" @submit.prevent @keydown.shift.enter="editItem(i, item.id)">
        <div class="form-group d-flex align-items-center">
          <input :value="item.user_name" class="form-control d-inline w-auto" type="text" name="user_name" placeholder="名前" required>
          <span class="date ml-1 d-none d-sm-inline">@{{ item.date }}</span>
          <div class="invalid-feedback">名前を入力してください</div>
          <button class="btn btn-outline-success btn-sm ml-auto" @click="toggleEditItem(i, item.id)">
            キャンセル
          </button>
        </div>
        <div class="form-group">
          <textarea class="form-control" name="body" rows="4" placeholder="内容" required @input="autosizeTextarea($event.target)"/>
          <div class="invalid-feedback">内容を入力してください</div>
        </div>
        <button class="btn btn-success" type="button" @click="editItem(i, item.id)">保存</button>
        <button class="btn btn-danger" type="button" @click="deleteItem(item.id)">削除</button>
      </form>
    </div>
  </div>
</template>
<script>
export default {
  props: {
    comments: {
      type: Array,
      required: true,
    },
    url: {
      type: String,
      required: true,
    },
    itemClass: {
      type: String,
      default: null,
    },
  },
  methods: {
    toggleEditItem(i, id) {
      const $form = $(this.$refs[`editForm${id}`]);
      this.editing = this.comments[i].editing;
      if (this.editing) {
        $form.removeClass('was-validated');
        this.$set(this.comments[i], 'editing', false);
      } else {
        this.$set(this.comments[i], 'editing', true);
      }
      if (!this.editing) {
        const $ta = $('textarea', $form);
        $ta.val(this.comments[i].body.trim());
        this.$nextTick(() => $ta.focus());
        this.autosizeTextarea($ta);
      }
    },
    editItem(i, id) {
      const $form = $(this.$refs[`editForm${id}`]);
      if (!$form.check()) return;
      const data = $form.serializeObject();
      axios.put(`${this.url}/${id}`, data).then(() => {
        this.toggleEditItem(i, id);
        this.$emit('done');
      }).catch(() => {
        this.$_notify('danger', '保存に失敗しました');
      });
    },
    deleteItem(id) {
      axios.delete(`${this.url}/${id}`).then(() => {
        this.$emit('done');
      }).catch(() => {
        this.$_notify('danger', '削除に失敗しました');
      });
    },
    autosizeTextarea(tgt) {
      // textareaの行数を内容に合わせて変更
      const $ta = _.isElement(tgt) ? $(tgt) : tgt;
      $ta.attr('rows', _.max([$ta.val().split('\n').length, 4]));
    },
  },
};
</script>
<style lang="scss" scoped>
.name {
  color: #040;
}
.date {
  color: brown;
}
</style>
