<template>
  <div class="input-group justify-content-center" :class="inline ? ['input-group-sm', 'd-inline-flex'] : null">
    <div v-if="!complete" class="input-group-prepend">
      <span class="input-group-text">検索</span>
    </div>
    <div class="dropdown" :class="{'input-group-sm': inline}">
      <input class="search form-control" :class="{'appended': clearWhenSet}" name="query" type="search" autocomplete="off" :placeholder="placeholder" @input="fetchCandidate">
      <div class="autocomplete dropdown-menu mt-0">
        <span v-if="complete">
          <a v-for="c in candidates" class="dropdown-item" href="#" @click="clickName">{{ c }}</a>
        </span>
        <span v-else>
          <a v-for="c in candidates" class="dropdown-item" href="#">{{ c }}</a>
        </span>
        <span v-if="searching">Searching...</span>
        <span v-else-if="input !== '' && candidates.length === 0">No matches found</span>
        <span v-else-if="input === ''">Please enter 1 or more character</span>
      </div>
    </div>
  </div>
</template>
<script>
// inputにv-modelを使うと入力確定前には値が取得できない
export default {
  props: {
    placeholder: {
      type: String,
      default: null,
    },
    complete: { // 補完 or リンク
      type: Boolean,
      default: true,
    },
    inline: {
      type: Boolean,
      default: false,
    },
    clearWhenSet: {
      type: Boolean,
      default: false,
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
      // すぐに消すとclickイベントが発生しない
      setTimeout(() => $('.autocomplete', e).removeClass('show'), 50);
    });
  },
  methods: {
    fetchCandidate() {
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
        this.$_notify('danger', '候補の取得に失敗しました。');
      });
    },
    clickName(e) {
      const name = $(e.target).html();
      if (this.clearWhenSet) {
        $('.search', this.$el).val('');
        this.input = '';
        this.candidates = [];
      } else {
        $('.search', this.$el).val(name);
        this.fetchCandidate();
      }
      this.$emit('complete', name, this.$el);
    },
  },
};
</script>
<style lang="scss" scoped>
.input-group-prepend + div .search {
  max-width: 150px;
  border-top-left-radius: 0;
  border-bottom-left-radius: 0;
}
.appended {
  border-top-right-radius: 0;
  border-bottom-right-radius: 0;
}
.dropdown-menu {
  max-height: 50vh;
  overflow-y: auto;
}
</style>
