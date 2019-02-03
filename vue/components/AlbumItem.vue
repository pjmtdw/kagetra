<template>
  <main id="container" class="mx-auto">
    <!-- ヘッダー -->
    <div v-if="loaded" class="d-flex flex-column bg-white px-2 py-3 shadow-sm">
      <div class="d-flex">
        <div>
          <h4 v-if="data.event_id" class="d-md-inline">
            <a :href="`result#/${data.event_id}`" class="card-link" title="大会結果へ">{{ data.name }}</a>
          </h4>
          <h4 v-else class="d-md-inline">{{ data.name }}</h4>
          <span class="date">@{{ data.date }}</span>
          <div class="w-100"/>
          <span class="text-muted">{{ data.place }}</span>
          <p v-if="!editing && data.comment" class="text-black-50 mt-2 mb-0">{{ data.comment }}</p>
        </div>
        <div class="ml-auto">
          <button class="btn btn-outline-success" @click="editing = !editing">{{ editing ? 'キャンセル' : '編集' }}</button>
        </div>
      </div>
      <div class="d-flex">
        <span class="text-muted ml-auto">撮影者: {{ data.owner_name }}</span>
      </div>
      <div v-show="editing" class="mt-2">
        <form class="px-2" @submit.prevent>
          <div class="form-group row">
            <label class="col-4 col-sm-2 col-form-label">コメント</label>
            <div class="col">
              <input v-model="edit.comment" type="text" class="form-control" placeholder="コメント">
            </div>
          </div>
          <div class="form-group form-check row">
            <label>
              <input v-model="edit.daily_choose" type="checkbox">
              <span>今日の一枚に選ぶ</span>
            </label>
          </div>
          <div class="form-group row">
            <label class="col-4 col-sm-2 col-form-label">
              <span>関連写真</span>
              <TooltipIcon title="解除するには下の関連写真自体をクリックします"/>
            </label>
            <div class="col d-flex">
              <div class="input-group">
                <input type="text" class="form-control" :value="relationsStr" readonly>
                <div class="input-group-append">
                  <button class="btn btn-success" data-toggle="modal" data-target="#album_search_dialog">追加</button>
                </div>
              </div>
            </div>
          </div>
        </form>
      </div>
      <div v-if="editing" class="d-flex">
        <button v-if="data.deletable" class="btn btn-danger" @click="deleteItem">削除</button>
        <button class="btn btn-success ml-auto" @click="saveItem">保存</button>
      </div>
    </div>
    <!-- タグ -->
    <div class="mt-3">
      <div v-if="loaded">
        <h6 class="text-black-50 ont-weight-bold border-bottom mt-2 mb-1">
          <span>タグ</span>
          <TooltipIcon title="写真をクリックするとタグを追加できます"/>
        </h6>
        <div class="d-flex flex-wrap px-1">
          <template v-if="!editing">
            <a v-for="t in data.tags" :key="t.id" href="#" class="tag border px-1" :class="{ active: tag === t }"
               @click.prevent="tag = (tag === t ? null : t)">
              {{ t.name }}
            </a>
          </template>
          <template v-else>
            <a v-for="t in edit.tags" :key="t.id" href="#" class="tag border px-1" :class="{ active: tag === t }">
              <span @click.prevent="tag = (tag === t ? null : t)">{{ t.name }}</span>
              <span class="text-muted font-weight-bold" @click="deleteTag(t)">&times;</span>
            </a>
          </template>
        </div>
      </div>
    </div>
    <!-- 写真 -->
    <div v-if="loaded" class="position-relative mt-2">
      <img ref="photo" :src="`/static/album/photo/${data.photo.id}`" :width="data.photo.width" :height="data.photo.height" @click="addTag">
      <img ref="marker" src="/img/album_marker/yellow.gif" class="d-none position-absolute">
    </div>
    <!-- 関連写真 -->
    <div v-if="data.relations && data.relations.length" class="mt-4">
      <div>
        <h6 class="text-black-50 ont-weight-bold border-bottom mt-2 mb-1">
          関連写真
        </h6>
      </div>
      <div class="d-flex flex-wrap">
        <div v-for="item in data.relations" class="p-2">
          <div class="card shadow-sm">
            <router-link :to="`/${item.id}`">
              <img :src="`/static/album/thumb/${item.thumb.id}`" class="card-img" :width="item.thumb.width" :height="item.thumb.height">
            </router-link>
          </div>
        </div>
      </div>
    </div>

    <!-- 写真選択 -->
    <div id="album_search_dialog" class="modal fade">
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
                <a href="#" data-dismiss="modal" @click.prevent="edit.relations.push(p)">
                  <img :src="`/static/album/thumb/${p.thumb.id}`" :width="p.thumb.width" :height="p.thumb.height">
                </a>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </main>
</template>
<script>
export default {
  props: {
    id: {
      type: Number,
      required: true,
    },
  },
  data() {
    return {
      data: {},
      tag: null,
      editing: false,
      edit: {},
      query: null,
      page: 1,
      count: null,
      pages: null,
      photoList: null,
    };
  },
  computed: {
    loaded() {
      return !_.isEmpty(this.data);
    },
    relationsStr() {
      if (!this.edit.relations) return null;
      return _.join(_.map(this.edit.relations, r => r.id), ', ');
    },
  },
  watch: {
    id() {
      this.fetch();
    },
    editing(toVal) {
      if (toVal) {
        this.edit = {
          comment: this.data.comment,
          daily_choose: this.data.daily_choose,
          relations: _.clone(this.data.relations),
          tags: _.clone(this.data.tags),
          tag_edit_log: {},
        };
      }
    },
    tag() {
      if (this.tag === null) {
        this.setMarker(['d-none']);
      } else {
        const t = this.tag;
        // const p = this.data.photo;
        // const w = $(this.$refs.photo).width();
        // const h = $(this.$refs.photo).height();
        this.setMarker([], {
          top: `${t.coord_y - t.radius}px`,
          left: `${t.coord_x - t.radius}px`,
        });
      }
    },
  },
  created() {
    this.fetch();
  },
  methods: {
    fetch() {
      axios.get(`/album/item/${this.id}`).then((res) => {
        this.data = res.data;
      });
    },
    setMarker(cls = [], style = {}) {
      const m = this.$refs.marker;
      cls.push('position-absolute');
      m.className = _.join(cls, ' ');
      m.style.cssText = _.join(_.map(style, (value, key) => `${key}: ${value};`), ' ');
    },
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
      }).catch(this.$_makeOnFail('検索結果を取得できませんでした'));
    },
    addTag(e) {
      if (!this.editing) return;
      this.$_prompt('タグ名').then((name) => {
        const min = _.min(_.map(_.keys(this.tag_edit_log), Number));
        const id = min < 0 ? min - 1 : -1;
        const data = {
          id,
          name,
          radius: 50,
          coord_x: e.offsetX,
          coord_y: e.offsetY,
        };
        this.edit.tags.push(data);
        this.edit.tag_edit_log[id] = ['update_or_create', data];
      });
    },
    deleteTag(t) {
      if (this.tag === t) this.tag = null;
      this.tag_edit_log[t.id] = ['destroy'];
    },
    saveItem() {
      const data = this.edit;
      data.comment_revision = this.data.comment_revision;
      axios.put(`/album/item/${this.id}`, _.omit(data, 'tags')).then(() => {
        this.fetch();
        this.editing = false;
      }).catch(this.$_makeOnFail('保存に失敗しました'));
    },
    deleteItem() {
      this.$_confirm('本当に削除していいですか？').then(() => {
        axios.delete(`/album/item/${this.id}`).then(() => {
          this.$router.push(`/group/${this.data.group.id}`);
        }).catch(this.$_makeOnFail('削除に失敗しました'));
      });
    },
  },
};
</script>
<style lang="scss" scoped>
#container {
  width: 100%;
  max-width: 750px;
}

.date {
  color: maroon;
}

.tag {
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
</style>
