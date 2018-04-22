<template>
  <form class="container mb-3" @submit.prevent>
    <div class="row">
      <div class="custom-file col-sm-6 col-12">
        <input :id="`file_input${index}`" type="file" name="file" class="custom-file-input text-truncate" @change="setFileName" multiple>
        <label :for="`file_input${index}`" class="custom-file-label">ファイルを選択</label>
      </div>
      <div class="col-sm-6 col-12 d-flex align-items-center p-0 mt-1 mt-sm-0">
        <label class="nowrap ml-sm-2 mr-1 mb-0" :for="`desc_input${index}`">
          説明
        </label>
        <input :id="`desc_input${index}`" v-model="description" type="text" name="description" class="form-control d-inline-block">
        <button type="button" class="btn btn-success ml-2 mr-1" @click="upload">送信</button>
        <button v-if="removable" type="button" class="close" aria-label="Close" @click="deleteForm">
          <span aria-hidden="true">&times;</span>
        </button>
      </div>
    </div>
  </form>
</template>
<script>
export default {
  props: {
    namespace: {
      type: String,
      default: '',
    },
    id: {
      type: Number,
      default: 0,
    },
    index: {
      type: Number,
      default: 1,
    },
    removable: {
      type: Boolean,
      default: false,
    },
  },
  data() {
    return {
      description: '',
    };
  },
  methods: {
    getFiles() {
      return $('input[type="file"]', this.$el)[0].files;
    },
    getFilename() {
      const files = this.getFiles();
      const n = files.length;
      if (n > 1) {
        return `${n}ファイル`;
      } else if (n === 1) {
        return files[0].name;
      }
      return null;
    },
    setFileName() {
      $('input[type="file"]').next().html(this.getFilename() || 'ファイルを選択');
    },
    deleteForm() {
      if (this.removable) {
        $(this.$el).hide();
      } else {
        $('input', this.$el).val(null);
        this.setFileName();
      }
    },
    upload() {
      const url = `/${this.namespace}/attached/${this.id}`;
      const files = this.getFiles();
      if (!files.length) {
        $.notify('warning', 'ファイルが選択されていません');
        return;
      }
      // 同時に送るとデータベースのロックでエラーになるので順番に送る
      /* eslint-disable arrow-body-style */
      _.reduce(files, (promise, file) => {
        return promise.then(() => {
          const data = new FormData();
          data.append('file', file);
          data.append('description', this.description);
          const config = {
            headers: {
              'content-type': 'multipart/form-data',
            },
            // onUploadProgress(progressEvent) {
            //   const percentCompleted =
            //       Math.round((progressEvent.loaded * 100) / progressEvent.total);
            // },
          };
          return axios.post(url, data, config);
        });
      }, Promise.resolve()).then(() => {
        $.notify('success', `${this.getFilename()}を送信しました.`);
        this.deleteForm();
        this.$emit('done');
      }).catch(() => {
        $.notify('danger', `${this.getFilename()}の送信に失敗しました.`);
      });
    },
  },
};
</script>
<style lang="scss" scoped>
@import '../../sass/common.scss';

.nowrap {
  white-space: nowrap;
}
</style>
