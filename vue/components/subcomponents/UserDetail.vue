<template>
  <div v-show="loaded" class="p-2">
    <div class="d-flex flex-row align-items-center">
      <span v-show="!editing" class="text-muted ml-auto">最終更新</span>
      <span v-show="!editing" class="ml-1">{{ userData.updated_date }}</span>
      <button v-show="editing" class="btn btn-sm btn-success ml-auto" @click="save">保存</button>
      <button v-if="userData.editable" class="btn btn-sm btn-outline-success ml-2" @click="editing = !editing; photo = userData.album_item">{{ editing ? 'キャンセル' : '編集' }}</button>
    </div>
    <!-- 属性 -->
    <div class="d-flex flex-row flex-wrap mt-2">
      <span class="text-muted">ユーザー属性</span>
      <span v-for="attr in userAttrs" class="attr ml-1">{{ attr.key }}: {{ attr.value }}</span>
    </div>
    <!-- 写真 -->
    <div class="mt-2">
      <div v-if="photo">
        <span class="text-muted">写真</span>
        <a :href="`/album#/${photo.id}`">
          <img :src="`/static/album/thumb/${photo.thumb.id}`" :width="photo.thumb.width" :height="photo.thumb.height">
        </a>
      </div>
      <div v-else>
        <span class="text-muted">写真</span>
        <span class="ml-1">未設定</span>
      </div>
      <div v-show="editing" class="mt-1">
        <button class="btn btn-success" data-toggle="modal" data-target="#album_search_dialog">写真変更</button>
        <button class="btn btn-danger" @click="photo = null">写真解除</button>
      </div>
    </div>
    <!-- データ -->
    <div class="mt-2">
      <table class="table table-sm table-striped bg-light">
        <tbody>
          <tr v-for="(v, k) in data">
            <th class="align-middle pl-2">{{ k }}</th>
            <td>
              <span v-show="!editing">{{ v }}</span>
              <input v-if="editing" v-model="edit[k]" type="text" class="form-control">
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    <!-- 写真選択 -->
    <div v-if="editing" id="album_search_dialog" ref="albumSearchDialog" class="modal fade">
      <div class="modal-dialog modal-lg">
        <div class="modal-content">
          <div class="modal-header">
            <h5 class="modal-title">写真を選ぶ</h5>
            <button type="button" class="close" data-dismiss="modal" aria-label="Close">
              <span aria-hidden="true">&times;</span>
            </button>
          </div>
          <div class="modal-body">
            <div class="input-group">
              <input v-model="query" class="form-control" name="query" type="search" placeholder="検索文字列" @keydown.enter="search(1, $event)">
              <div class="input-group-append">
                <button class="btn btn-secondary" type="button" @click="search(1, $event)">検索</button>
              </div>
            </div>
            <div v-if="count === 0 || count">
              {{ count }}件
            </div>
            <ul v-if="pages > 1" class="pagination justify-content-center mt-3">
              <li v-for="i in pages" class="page-item" :class="{ active: page === i }" :key="i">
                <a href="#" class="page-link" @click.prevent="search(i)">{{ i }}</a>
              </li>
            </ul>
            <div class="d-flex flex-row flex-wrap">
              <div v-for="p in photoList" :key="p.id" class="p-1">
                <a href="#" data-dismiss="modal" @click.prevent="photo = p">
                  <img :src="`/static/album/thumb/${p.thumb.id}`" :width="p.thumb.width" :height="p.thumb.height">
                </a>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
<script>
/* global CryptoJS */

export default {
  props: {
    password: {
      type: String,
      required: true,
    },
    userData: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      editing: false,
      edit: {},
      query: null,
      page: 1,
      count: null,
      pages: null,
      photo: null,
      photoList: null,
    };
  },
  computed: {
    loaded() {
      return !_.isEmpty(this.userData);
    },
    userAttrs() {
      if (_.isUndefined(this.userData.user_attrs)) return null;
      return _.map(this.userData.user_attrs, a => ({ key: a[0], value: a[1] }));
    },
    data() {
      if (_.isUndefined(this.userData.found)) return null;
      if (!this.userData.found) return this.userData.default;
      const decrypted = CryptoJS.AES.decrypt(this.userData.text, this.password);
      return JSON.parse(decrypted.toString(CryptoJS.enc.Utf8));
    },
  },
  watch: {
    userData() {
      this.editing = false;
      this.photo = this.userData.album_item;
      this.query = null;
      this.page = 1;
      this.count = null;
      this.pages = null;
      this.photo = null;
      this.photoList = null;
    },
    editing(toVal) {
      if (toVal) {
        this.edit = _.clone(this.data);
      }
    },
  },
  methods: {
    search(page, e) {
      if (e && e.isComposing) return;
      const data = {
        qs: this.query,
        page,
      };
      axios.post('/album/search', data).then((res) => {
        this.page = page;
        this.pages = res.data.pages;
        this.photoList = res.data.list;
        this.count = res.data.count;
        this.prevQuery = this.query;
      }).catch(this.$_makeOnFail('検索結果を取得できませんでした'));
    },
    save() {
      const validations = [
        { key: '名前', pattern: /^\s*\S+\s+\S+\s*$/, message: '名前の姓と名の間に空白を入れて下さい' },
        { key: 'ふりがな', pattern: /^\s*\S+\s+\S+\s*$/, message: 'ふりがなの姓と名の間に空白を入れて下さい' },
      ];
      let isValid = true;
      _.each(validations, (v) => {
        if (!v.pattern.test(this.edit[v.key])) {
          this.$_notify('warning', v.message);
          isValid = false;
        }
      });
      if (!isValid) return;
      const text = CryptoJS.AES.encrypt(JSON.stringify(this.edit), this.password).toString(CryptoJS.enc.BASE64);
      axios.post(`/addrbook/item/${this.userData.uid}`, { text, album_item_id: this.photo === null ? null : this.photo.id }).then(() => {
        this.editing = false;
        this.$emit('done');
      }).catch(this.$_makeOnFail('保存しました'));
    },
  },
};
</script>
<style lang="scss" scoped>
.attr {
  border: 1px dotted rgba(0, 0, 0, .1);
}
</style>
