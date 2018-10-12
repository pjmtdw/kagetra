<template>
  <div>
    <table class="table table-striped table-sm border">
      <tbody>
        <tr v-for="f in fileList" :key="f.id">
          <td>
            <a :href="`/static/${namespace}/attached/${f.id}/${encodeURI(f.orig_name)}`">{{ f.orig_name }}</a>
          </td>
          <td v-if="f.size" class="size">
            {{ formatSize(f.size) }}
          </td>
          <td v-if="f.date" class="date">
            {{ f.date }}
          </td>
          <td>
            {{ f.description }}
          </td>
          <td v-if="f.editable !== false">
            <button class="btn btn-sm btn-outline-success" @click="editFile(f)">編集</button>
          </td>
        </tr>
      </tbody>
    </table>
    <div ref="editFileDialog" class="modal fade">
      <div class="modal-dialog shadow">
        <div class="modal-content">
          <div class="modal-header">
            <h5 class="modal-title">添付ファイル編集</h5>
            <button class="close" @click="hide">&times;</button>
          </div>
          <div class="modal-body p-3">
            <form>
              <label class="w-100 mb-0">
                <span>ファイル名</span>
                <input v-model="edit.orig_name" type="text" class="form-control">
              </label>
              <div class="mt-2">
                <span>ファイル</span>
                <div class="custom-file">
                  <input id="file_input" ref="fileInput" type="file" name="file" class="custom-file-input text-truncate" @change="setFileName">
                  <label for="file_input" class="custom-file-label">{{ filename }}</label>
                </div>
              </div>
              <label class="w-100 mb-0">
                <span>説明</span>
                <input v-model="edit.description" type="text" class="form-control">
              </label>
            </form>
          </div>
          <div class="modal-footer d-flex flex-row">
            <button class="btn btn-danger" @click="deleteFile()">削除</button>
            <button class="btn btn-outline-secondary ml-auto" @click="hide">キャンセル</button>
            <button class="btn btn-success ml-2" @click="saveFile()">保存</button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
<script>
export default {
  props: {
    namespace: {
      type: String,
      required: true,
    },
    id: {
      type: Number,
      required: true,
    },
    fileList: {
      validator(v) {
        return _.isArray(v) || _.isNil(v);
      },
      required: true,
    },
  },
  data() {
    return {
      $dialog: null,
      edit: {},
      filename: null,
    };
  },
  mounted() {
    this.$dialog = $(this.$refs.editFileDialog);
    const parents = this.$dialog.parents('div.modal');
    this.$dialog.on('show.bs.modal', () => {
      // こうしないとEventEditDialogがうまく背面にならない
      parents.removeClass('modal');
      parents.addClass('modal-back');
    });
    this.$dialog.on('hide.bs.modal', (e) => {
      // こうしないとEventEditDialogがうまく背面にならない
      parents.addClass('modal');
      parents.removeClass('modal-back');
      e.stopPropagation();
    });
  },
  methods: {
    formatSize(size) {
      if (size < 1024) return `${size} bytes`;
      else if (size < 1024 * 1024) return `${_.floor(size / 1024)} KB`;
      return `${_.floor(size / (1024 * 1024))} KB`;
    },
    getFile() {
      return this.$refs.fileInput.files[0];
    },
    setFileName() {
      this.filename = this.getFile().name;
      this.edit.orig_name = this.filename;
    },
    editFile(f) {
      this.edit = _.clone(f);
      this.$dialog.modal('show');
    },
    hide() {
      this.$dialog.modal('hide');
    },
    saveFile() {
      const data = new FormData();
      const file = this.getFile();
      data.append('attached_id', this.edit.id);
      data.append('orig_name', this.edit.orig_name);
      data.append('description', this.edit.description);
      if (file) data.append('file', file);
      axios.post(`/${this.namespace}/attached/${this.id}`, data, {
        headers: {
          'content-type': 'multipart/form-data',
        },
      }).then(() => {
        this.$_notify('保存しました');
        this.$dialog.modal('hide');
        this.$emit('done');
      }).catch(this.$_makeOnFail(file ? `${file.name}の送信に失敗しました` : '保存に失敗しました'));
    },
    deleteFile() {
      this.$_confirm(`${this.edit.orig_name}を削除していいですか？`).then(() => {
        axios.delete(`/${this.namespace}/attached/${this.edit.id}`).then(() => {
          this.$_notify('削除しました');
          this.$dialog.modal('hide');
          this.$emit('done');
        }).catch(this.$_makeOnFail('削除に失敗しました'));
      });
    },
  },
};
</script>
<style lang="scss">
.modal-back {
  position: fixed;
  top: 0;
  bottom: 0;
  left: 0;
  right: 0;
  z-index: 1049;  // .modalが1050
}
</style>
