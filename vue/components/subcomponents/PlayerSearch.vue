<template>
  <div>
    <input v-if="bind" class="form-control" :class="[classInput, { append }, { prepend }]" type="search" autocomplete="off" :placeholder="placeholder" :value="value"
           @input="fetchCandidate($event.target.value)" @focus="onFocus" @blur="onBlur" @keypress.enter="onEnter">
    <input v-else ref="input" class="form-control" :class="[classInput, { append }, { prepend }]" type="search" autocomplete="off" :placeholder="placeholder"
           @input="fetchCandidate($event.target.value)" @focus="onFocus" @blur="onBlur" @keypress.enter="onEnter">
    <div class="dropdown" :class="{ show: focused }">
      <div class="dropdown-menu mt-0" :class="{ show: focused }">
        <template v-if="link">
          <router-link v-for="c in candidates" :key="c" class="dropdown-item" :to="`/record/${c}`" @click.native="clickName(c)">{{ c }}</router-link>
        </template>
        <template v-else>
          <a v-for="c in candidates" :key="c" class="dropdown-item" href="#" @click.prevent="clickName(c)">{{ c }}</a>
        </template>
        <!-- <a v-for="c in candidates" :key="c" class="dropdown-item" href="#" @click.prevent="clickName(c)">{{ c }}</a> -->
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
    // v-modelを使用
    bind: {
      type: Boolean,
      default: false,
    },
    value: {
      type: String,
      default: '',
    },
    // inputタグに適用するクラス
    classInput: {
      type: [String, Array, Object],
      default: null,
    },
    // inputタグのplaceholder
    placeholder: {
      type: String,
      default: null,
    },
    // 選択した人の個人記録を表示
    link: {
      type: Boolean,
      default: false,
    },
    // 選択後にinputをクリア
    clear: {
      type: Boolean,
      default: false,
    },
    // styling
    append: {
      type: Boolean,
      default: false,
    },
    prepend: {
      type: Boolean,
      default: false,
    },
  },
  data() {
    return {
      input: '',
      focused: false,
      searching: false,
      candidates: [],
    };
  },
  methods: {
    fetchCandidate(q) {
      if (this.bind) {
        this.$emit('input', q);
      }
      if (q === '') {
        this.candidates = [];
        return;
      }
      this.input = q;
      this.searching = true;
      axios.post('/api/result_misc/search_name', { q }).then((res) => {
        this.searching = false;
        this.candidates = res.data.results;
      }).catch(() => {
        this.$_notify('danger', '候補の取得に失敗しました。');
      });
    },
    clickName(name) {
      if (this.bind) {
        this.$emit('input', name);
        return;
      }
      if (this.clear) {
        this.$refs.input.value = '';
        this.candidates = [];
      } else {
        this.$refs.input.value = name;
      }
      this.$emit('done', name, this.$el);
    },
    onFocus() {
      this.focused = true;
      if (this.bind) return;
      if (this.$refs.input.value === '') {
        this.input = '';
        this.candidates = [];
      }
    },
    onBlur() {
      // すぐに消すとclickイベントが発生しない
      setTimeout(() => { this.focused = false; }, 50);
    },
    onEnter() {
      if (this.bind) return;
      this.$emit('enter', this.$refs.input.value, this.$el);
      if (this.clear) {
        this.$refs.input.value = '';
        this.candidates = [];
      }
    },
  },
};
</script>
<style lang="scss" scoped>
.append {
  border-top-left-radius: 0;
  border-bottom-left-radius: 0;
}
.prepend {
  border-top-right-radius: 0;
  border-bottom-right-radius: 0;
}
.dropdown-menu {
  max-height: 50vh;
  overflow-y: auto;
}
</style>
