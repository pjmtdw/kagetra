<template>
  <main id="container" class="mx-auto">
    <!-- ヘッダー -->
    <div v-if="loaded" class="d-flex flex-column bg-white px-2 py-3 shadow-sm">
      <div class="d-flex">
        <div v-show="!editing">
          <h4 v-if="data.event_id" class="d-md-inline">
            <a :href="`result#/${data.event_id}`" class="card-link" title="大会結果へ">{{ data.name }}</a>
          </h4>
          <h4 v-else class="d-md-inline">{{ data.name }}</h4>
          <span v-if="data.start_at && data.start_at === data.end_at" class="date">@{{ data.start_at }}</span>
          <span v-else-if="data.start_at && data.end_at" class="date">@{{ data.start_at }} &sim; {{ data.end_at }}</span>
          <span v-else-if="data.start_at" class="date">@{{ data.start_at }}</span>
          <span v-else-if="data.end_at" class="date">@&sim; {{ data.start_at }}</span>
          <div class="w-100"/>
          <span class="text-muted">{{ data.place }}</span>
          <p v-if="data.comment" class="text-black-50 mt-1 mb-0">{{ data.comment }}</p>
        </div>
        <div v-show="editing" class="flex-grow-1">
          <form class="px-2" @submit.prevent>
            <div class="form-group row">
              <label class="col-4 col-sm-2 col-form-label">タイトル</label>
              <div class="col">
                <input v-model="editAlbum.name" type="text" class="form-control" placeholder="タイトル">
              </div>
            </div>
            <div class="form-group row">
              <label class="col-4 col-sm-2 col-form-label">開始日</label>
              <div class="col">
                <input v-model="editAlbum.start_at" type="date" class="form-control" placeholder="開始日(YYYY-MM-DD)">
              </div>
            </div>
            <div class="form-group row">
              <label class="col-4 col-sm-2 col-form-label">終了日</label>
              <div class="col">
                <input v-model="editAlbum.end_at" type="date" class="form-control" placeholder="終了日(YYYY-MM-DD)">
              </div>
            </div>
            <div class="form-group row">
              <label class="col-4 col-sm-2 col-form-label">場所</label>
              <div class="col">
                <input v-model="editAlbum.place" type="text" class="form-control" placeholder="場所">
              </div>
            </div>
            <div class="form-group row">
              <label class="col-4 col-sm-2 col-form-label">コメント</label>
              <div class="col">
                <input v-model="editAlbum.comment" type="text" class="form-control" placeholder="コメント">
              </div>
            </div>
            <div class="form-group row">
              <label class="col-4 col-sm-2 col-form-label">関連大会</label>
              <div class="col">
                <div class="input-group">
                  <input type="text" class="form-control" :value="editAlbum.event_id" readonly>
                  <div class="input-group-append">
                    <button class="btn btn-success" data-toggle="modal" data-target="#select_event_dialog">変更</button>
                  </div>
                </div>
              </div>
            </div>
          </form>
        </div>
        <div class="ml-auto">
          <button v-show="!editing" class="btn btn-success mr-2" data-toggle="modal" data-target="#upload_photo_dialog">追加</button>
          <button class="btn btn-outline-success" @click="editing = !editing">{{ editing ? 'キャンセル' : '編集' }}</button>
        </div>
      </div>
      <div v-if="editing" class="d-flex">
        <button v-if="data.deletable" class="btn btn-danger" @click="deleteAlbum">削除</button>
        <button class="btn btn-success ml-auto" @click="saveAlbum">保存</button>
      </div>
    </div>
    <!-- 絞り込み -->
    <div v-if="loaded">
      <h6 class="text-black-50 ont-weight-bold border-bottom mt-2 mb-1">撮影者</h6>
      <div class="d-flex flex-wrap px-1">
        <a v-for="(v, name) in data.owners" :key="name" href="#" class="owner border px-1" :class="{ active: owner === name }" @click.prevent="owner = (owner === name ? null : name)">
          {{ name }}({{ v.length }})
        </a>
      </div>
    </div>
    <div v-if="loaded">
      <h6 class="text-black-50 ont-weight-bold border-bottom mt-2 mb-1">タグ</h6>
      <div class="d-flex flex-wrap px-1">
        <a v-for="(v, name) in data.tags" :key="name" href="#" class="tag border px-1" :class="{ active: tag === name }" @click.prevent="tag = (tag === name ? null : name)">
          {{ name }}({{ v.length }})
        </a>
        <a href="#" class="tag border px-1" :class="{ active: tag === 'no-tag' }" @click.prevent="tag = (tag === 'no-tag' ? null : 'no-tag')">
          タグなし({{ noTagCount }})
        </a>
        <a href="#" class="tag border px-1" :class="{ active: tag === 'no-comment' }" @click.prevent="tag = (tag === 'no-comment' ? null : 'no-comment')">
          コメントなし({{ noCommentCount }})
        </a>
      </div>
    </div>
    <!-- 写真 -->
    <div class="d-flex flex-wrap mt-3">
      <div v-for="item in filteredItems" class="p-2">
        <div class="card shadow-sm">
          <router-link :to="`/${item.id}`">
            <img :src="`/static/album/thumb/${item.thumb.id}`" :class="item.no_comment ? 'card-img' : 'card-img-top'" :width="item.thumb.width" :height="item.thumb.height">
          </router-link>
          <div v-if="!item.no_comment" class="card-body p-1">
            <p class="card-text">{{ item.comment }}</p>
          </div>
        </div>
      </div>
    </div>

    <!-- 写真アップロード -->
    <div id="upload_photo_dialog" class="modal fade">
      <div class="modal-dialog">
        <div class="modal-content">
          <div v-if="uploaded || uploading" class="progress">
            <div class="progress-bar" :style="{ width: `${animateProgress}%` }"/>
          </div>
          <div class="modal-header">
            <h5 class="modal-title">写真アップロード</h5>
            <button type="button" class="close" data-dismiss="modal">&times;</button>
          </div>
          <div class="modal-body">
            <MultiFileInput ref="photoInput" @change="uploaded = false"/>
            <p class="mb-0"><small class="text-muted">各画像ファイルの拡張子はpng,jpg,gifのどれかにして下さい</small></p>
            <p class="mb-0"><small class="text-muted">画像をzipファイルにまとめれば一度に複数送信できます</small></p>
            <p class="mb-0"><small class="text-muted">アップロードは画像一枚につき1〜2秒かかります．気長にお待ち下さい</small></p>
          </div>
          <div class="modal-footer">
            <button class="btn btn-outline-secondary" data-dismiss="modal">キャンセル</button>
            <button class="btn btn-success ml-2" @click="submitPhotos">{{ uploaded ? '完了' : '送信' }}</button>
          </div>
        </div>
      </div>
    </div>

    <!-- 関連大会 -->
    <div id="select_event_dialog" class="modal fade">
      <div class="modal-dialog">
        <div class="modal-content">
          <div class="modal-header">
            <h5 class="modal-title">関連大会変更</h5>
            <button class="close">&times;</button>
          </div>
          <div class="modal-body">
            <div class="input-group">
              <input v-model.lazy="query" type="search" class="form-control" placeholder="例: 「名人戦 2018」">
              <div class="input-group-append">
                <button class="btn btn-secondary">検索</button>
              </div>
            </div>
            <div class="list-group mt-3">
              <a v-for="c in candidates" :key="c.id" href="#" class="list-group-item list-group-item-action" @click.prevent="select(c.id)">
                {{ c.text }}
              </a>
            </div>
          </div>
        </div>
      </div>
    </div>
  </main>
</template>
<script>
import MultiFileInput from '../basics/MultiFileInput.vue';

export default {
  components: {
    MultiFileInput,
  },
  props: {
    id: {
      type: Number,
      required: true,
    },
  },
  data() {
    return {
      data: {},
      owner: null,
      tag: null,
      editing: false,
      editAlbum: {},

      // upload
      $uploadDialog: null,
      uploaded: false,
      uploading: false,
      progress: 0,
      animateProgress: 0,

      // event
      $selectEventDialog: null,
      query: null,
      candidates: null,
    };
  },
  computed: {
    loaded() {
      return !_.isEmpty(this.data);
    },
    noTagCount() {
      return _.sumBy(this.data.items, i => i.no_tag);
    },
    noCommentCount() {
      return _.sumBy(this.data.items, i => i.no_comment);
    },
    filteredItems() {
      let filtered = _.filter(this.data.items, (item) => {
        if (this.owner === null) return true;
        return _.includes(this.data.owners[this.owner], item.id);
      });
      filtered = _.filter(filtered, (item) => {
        if (this.tag === null) return true;
        else if (this.tag === 'no-tag') return item.no_tag;
        else if (this.tag === 'no-comment') return item.no_comment;
        return _.includes(this.data.tags[this.tag], item.id);
      });
      return filtered;
    },
  },
  watch: {
    editing(toVal) {
      if (!toVal) return;
      this.editAlbum = {
        name: this.data.name,
        start_at: this.data.start_at,
        end_at: this.data.end_at,
        place: this.data.place,
        comment: this.data.comment,
        event_id: this.data.event_id,
      };
    },
    progress(toVal, fromVal) {
      const id = setInterval(() => {
        this.animateProgress += 1;
      }, 10 / (toVal - fromVal));
      setTimeout(() => {
        this.animateProgress = toVal;
        clearInterval(id);
      }, 10);
    },
    query() {
      this.search();
    },
  },
  created() {
    this.fetch();
  },
  mounted() {
    this.$uploadDialog = $('#upload_photo_dialog');
    this.$selectEventDialog = $('#select_event_dialog');
    this.$uploadDialog.on('hide.bs.modal', () => {
      this.fetch();
      this.uploaded = false;
      this.$refs.photoInput.reset();
    });
  },
  methods: {
    fetch() {
      axios.get(`/album/group/${this.id}`).then((res) => {
        res.data.owners = _.zipObject(_.map(res.data.owners, v => v[0]), _.map(res.data.owners, v => v[1]));
        res.data.tags = _.zipObject(_.map(res.data.tags, v => v[0]), _.map(res.data.tags, v => v[1]));
        this.data = res.data;
      }).catch(this.$_makeOnFail('取得に失敗しました'));
    },
    saveAlbum() {
      axios.put(`/album/group/${this.id}`, this.editAlbum).then(() => {
        this.editing = false;
        this.fetch();
      }).catch(this.$_makeOnFail('保存に失敗しました'));
    },
    deleteAlbum() {
      this.$_confirm(`本当にアルバム「${this.data.name || '(タイトル無し)'}」を削除していいですか？`).then(() => {
        axios.delete(`/album/group/${this.id}`).then(() => {
          this.$router.push('/');
        }).catch(this.$_makeOnFail('削除に失敗しました'));
      });
    },

    // upload
    submitPhotos() {
      if (this.uploaded) {
        this.$uploadDialog.modal('hide');
        return;
      }
      const input = this.$refs.photoInput;
      const { files } = input;
      if (!files.length) {
        this.$_notify('warning', '写真が選択されていません');
        return;
      }
      if (!_.every(files, f => /(jpe?g|png|gif|zip)$/i.test(f.name))) {
        this.$_notify('warning', '使用できる拡張子はpng, jpg, gif, zipです');
        return;
      }

      const step = 100 / files.length / 2;
      this.uploading = true;
      this.progress = 0;
      this.animateProgress = 0;
      /* eslint-disable-next-line arrow-body-style */
      _.reduce(files, (promise, file) => {
        return promise.then(() => {
          this.progress += step;
          const data = new FormData();
          data.append('file', file);
          data.append('group_id', this.id);
          const config = {
            headers: {
              'content-type': 'multipart/form-data',
            },
          };
          return axios.post('/album/upload', data, config).then(() => {
            this.progress += step;
          });
        });
      }, Promise.resolve()).then(() => {
        this.uploaded = true;
        this.uploading = false;
        this.$_notify(`${input.filename}を送信しました`);
        input.reset();
      }).catch(() => {
        this.uploading = false;
        this.$_notify('danger', `${input.filename}の送信に失敗しました`);
      });
    },

    // select event
    search() {
      const data = {
        q: this.query,
        group_id: this.id,
      };
      axios.post('/album/complement_event', data).then((res) => {
        this.candidates = res.data.results;
      });
    },
    select(id) {
      this.editAlbum.event_id = id;
      this.$selectEventDialog.modal('hide');
    },
  },
};
</script>
<style lang="scss" scoped>
#container {
  width: 100%;
  max-width: 750px;
}

.owner, .tag {
  color: black;
  margin-left: -1px;
  &:hover {
    text-decoration: none;
    background-color: #ddd;
  }
  &.active {
    background-color: #ddd;
  }
}

.progress {
  height: .3rem;
}

.date {
  color: maroon;
}
</style>
