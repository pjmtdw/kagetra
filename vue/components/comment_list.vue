<template>
  <div class="list-group list-group-flush">
    <div v-for="item in comments" :key="item.id" class="list-group-item bg-transparent" :class="item_class">
      <div class="d-flex">
        <span class="name">{{ item.user_name }}</span>
        <span class="date">@{{ item.date }}</span>
        <h6 v-if="item.is_new" class="align-self-center"><span class="badge badge-info mx-1">New</span></h6>
        <button class="edit-item btn btn-outline-success btn-sm ml-auto" v-if="item.editable" :data-id="item.id" @click="toggle_edit_item">
          編集
        </button>
      </div>
      <div :id="`item${item.id}`" class="pre mt-1 pl-2">{{ item.body }}</div>
      <form :id="'editItem' + item.id" class="mt-3 d-none" v-if="item.editable" :data-id="item.id" @submit.prevent>
        <button class="btn btn-success" type="button" @click="edit_item">保存</button>
        <button class="btn btn-danger" type="button" @click="delete_item">削除</button>
        <input class="form-control w-auto my-2" type="text" name="user_name" placeholder="名前" :value="item.user_name" required>
        <textarea class="form-control" name="body" rows="4" placeholder="内容" @input="autosize_textarea(this.$($event.target))" required/>
      </form>
    </div>
  </div>
</template>
<script>
export default {
  props: {
    comments: {
      type: Array,
      default() {
        return [];
      },
    },
    url: {
      type: String,
      default: null,
    },
    item_class: {
      type: String,
      default: null,
    },
  },
  methods: {
    toggle_edit_item(e) {
      const $editToggle = $(e.target);
      const id = $editToggle.attr('data-id');
      const $item = $(`#item${id}`);
      const $edit = $(`#editItem${id}`);
      $editToggle.toggleBtnText('編集', 'キャンセル');
      $item.toggleClass('d-none');
      $edit.toggleClass('d-none');
      if ($editToggle.data('toggled')) {
        const $ta = $('textarea', $edit);
        $ta.val($item.html().trim());
        $ta.focus();
        this.autosize_textarea($ta);
      }
    },
    edit_item(e) {
      const $form = $(e.target).parents('form');
      const id = Number($form.attr('data-id'));
      const $toggle = $(`button[data-id="${id}"]`);
      const data = $form.serializeObject();
      if (!$form.check()) {
        if (!data.body) $.notify('warning', '内容がありません');
        if (!data.user_name) $.notify('warning', '名前を入力してください');
        return;
      }
      axios.put(`${this.url}/${id}`, data).then(() => {
        $form.removeClass('was-validated');
        $toggle.click();
        $.notify('success', '変更を保存しました');
        this.$emit('done');
      }).catch(() => {
        $.notify('danger', '保存に失敗しました');
      });
    },
    delete_item(e) {
      const $form = $(e.target).parents('form');
      const id = Number($form.attr('data-id'));
      axios.delete(`${this.url}/${id}`).always(() => {
        $.notify('success', '削除しました');
        this.$emit('done');
      });
    },
    autosize_textarea($ta) {
      // textareaの行数を内容に合わせて変更
      $ta.attr('rows', _.max([$ta.val().split('\n').length, 4]));
    },
  },
};
</script>
<style lang="scss" scoped>
@import '../sass/common.scss';
.name {
  color: #040;
}
.date {
  color: brown;
}
</style>
