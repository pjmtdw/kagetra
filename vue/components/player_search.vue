<template>
  <div class="input-group justify-content-center">
    <div class="input-group-prepend">
      <span class="input-group-text">検索</span>
    </div>
    <div class="dropdown">
      <input class="search form-control" name="query" type="text" autocomplete="off" :placeholder="placeholder" @input="fetch_candidate">
      <div class="autocomplete dropdown-menu mt-0">
        <a v-for="c in candidates" class="dropdown-item" href="#">{{ c }}</a>
        <span v-if="searching">Searching...</span>
        <span v-if="input !== '' && candidates.length === 0">No matches found</span>
        <span v-if="input === ''">Please enter 1 or more character</span>
      </div>
    </div>
  </div>
</template>
<script>
export default {
  props: {
    id: {
      type: String,
      default: '',
    },
    placeholder: {
      type: String,
      default: '',
    },
  },
  data() {
    return {
      input: '',
      searching: false,
      candidates: [],
    };
  },
  mounted() {
    const e = this.$el;
    $('.search', e).focus(() => {
      $('.autocomplete', e).addClass('show');
    }).blur(() => {
      $('.autocomplete', e).removeClass('show');
    });
  },
  methods: {
    fetch_candidate() {
      const url = '/api/result_misc/search_name';
      const q = $('.search', this.$el).val();
      if (q === this.input) return;
      else if (q === '') {
        this.candidates = [];
        this.input = '';
        return;
      }
      this.input = q;
      this.searching = true;
      axios.post(url, { q }).then((res) => {
        this.searching = false;
        this.candidates = res.data.results;
      }).catch(() => {
        $.notify('danger', '候補の取得に失敗しました。');
      });
    },
  },
};
</script>
<style lang="scss" scoped>
// @import '../sass/common.scss';
.search {
  max-width: 150px;
  border-top-left-radius: 0;
  border-bottom-left-radius: 0;
}
.dropdown-menu {
  max-height: 50vh;
  overflow-y: auto;
}
</style>
