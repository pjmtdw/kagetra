<template>
  <form class="container mb-3" @submit.prevent>
    <div class="row">
      <div class="custom-file col-sm-6 col-12">
        <input type="file" name="file" :id="`file_input${index}`" class="custom-file-input text-truncate" @change="set_filename" multiple>
        <label :for="`file_input${index}`" class="custom-file-label">ファイルを選択</label>
      </div>
      <div class="col-sm-6 col-12 d-flex align-items-center p-0 mt-1 mt-sm-0">
        <label class="nowrap ml-sm-2 mr-1 mb-0" :for="`desc_input${index}`">
          説明
        </label>
        <input :id="`desc_input${index}`" type="text" name="description" class="form-control d-inline-block" v-model="description">
        <button type="button" class="btn btn-success ml-2 mr-1" @click="upload">送信</button>
        <button type="button" class="close" aria-label="Close" @click="delete_form">
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
  },
  data() {
    return {
      description: '',
    };
  },
  methods: {
    files() {
      return $('input[type="file"]', this.$el)[0].files;
    },
    filename() {
      const files = this.files();
      const n = files.length;
      if (n > 1) {
        return `${n}ファイル`;
      } else if (n === 1) {
        return files[0].name;
      }
      return null;
    },
    set_filename(e) {
      $(e.target).next().html(this.filename() || 'ファイルを選択');
    },
    delete_form() {
      $(this.$el).hide();
    },
    upload() {
      const url = `/${this.namespace}/attached/${this.id}`;
      // 同時に送るとデータベースのロックでエラーになるので順番に送る
      /* eslint-disable arrow-body-style */
      _.reduce(this.files(), (promise, file) => {
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
        $.notify('success', `${this.filename()}を送信しました.`);
        this.delete_form();
        this.$emit('done');
      }).catch(() => {
        $.notify('danger', `${this.filename()}の送信に失敗しました.`);
      });
    },
  },
};
</script>
<style lang="scss" scoped>
@import '../sass/common.scss';

.nowrap {
  white-space: nowrap;
}
</style>
