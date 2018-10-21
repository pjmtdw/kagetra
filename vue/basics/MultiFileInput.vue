<template>
  <div class="custom-file">
    <input :id="`file_input${id}`" :ref="`file_input${id}`" type="file" name="file" class="custom-file-input text-truncate" @change="onChange" multiple>
    <label :for="`file_input${id}`" class="custom-file-label">{{ filename }}</label>
  </div>
</template>
<script>
export default {
  data() {
    return {
      id: _.uniqueId(),
      files: [],
    };
  },
  computed: {
    filename() {
      const n = this.files.length;
      if (n > 1) {
        return `${n}ファイル`;
      } else if (n === 1) {
        return this.files[0].name;
      }
      return null;
    },
  },
  methods: {
    onChange() {
      this.files = this.$refs[`file_input${this.id}`].files;
      this.$emit('change');
    },
    reset() {
      this.files = [];
    },
  },
};
</script>
