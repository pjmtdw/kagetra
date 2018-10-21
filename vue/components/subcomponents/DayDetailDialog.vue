<template>
  <div class="modal fade" tabindex="-1" role="dialog">
    <div class="modal-dialog modal-lg" role="document">
      <div v-if="detail" class="modal-content">
        <div class="modal-header">
          <h5 class="modal-title">
            {{ detail.year }}年{{ detail.month }}月{{ detail.date }}日 (<span class="font-weight-bold">{{ weekday_ja[detail.day] }}</span>)
            <span v-for="n in detail.info.names" :class="{ 'text-danger': detail.info.is_holiday }">{{ n }}</span>
          </h5>
          <button type="button" class="close ml-1" data-dismiss="modal">&times;</button>
        </div>
        <div class="modal-body">
          <template v-for="e in detail.events">
            <div :key="e.id" class="d-flex flex-column flex-lg-row">
              <div>
                <h6 class="mb-1">
                  {{ e.name }}
                  <span class="place">@{{ e.place }}</span>
                </h6>
                <span class="ml-1 text-muted" v-html="$_timeRange(e.start_at, e.end_at)"/>
              </div>
              <div class="ml-auto">
                <button class="btn btn-info" @click="openInfo(e.id)">情報</button>
                <button v-if="!gIsPublic" class="btn btn-info" @click="openComment(e.id)">コメント({{ e.comment_count }})</button>
              </div>
            </div>
            <hr>
          </template>
          <template v-for="x in detail.list">
            <template v-if="!gIsPublic || x.public">
              <div :key="x.id" class="d-flex flex-row justify-content-between">
                <div v-show="!x.editing">
                  <h6 class="mb-1">
                    <span :class="{ emph: x.emph_name }">{{ x.name }}</span>
                    <span class="place" :class="{ emph: x.emph_place }">@{{ x.place }}</span>
                  </h6>
                  <div class="ml-1 text-muted" v-html="$_timeRange(x.start_at, x.end_at, x.emph_start_at, x.emph_end_at)"/>
                  <div v-if="x.description" class="alert alert-secondary small px-3 py-2">
                    {{ x.description }}
                  </div>
                </div>
                <div v-show="x.editing"/>
                <div>
                  <button v-if="x.editable" class="btn btn-outline-success" @click="toggleEditItem(x)">{{ x.editing ? 'キャンセル' : '編集' }}</button>
                </div>
              </div>
              <form v-if="x.editable" v-show="x.editing" :id="`editForm${x.id}`" class="mt-3" @submit.prevent>
                <div class="form-row align-items-center">
                  <input type="text" name="name" class="form-control col-9 col-sm-6" placeholder="タイトル" :value="x.name" required>
                  <label class="col mb-0">
                    <input type="checkbox" name="emph_name" :checked="x.emph_name">
                    強調
                  </label>
                  <div class="d-block d-sm-none w-100 mt-3"/>
                  <select type="text" name="kind" class="custom-select col-6 col-sm-2 mr-2">
                    <option value="practice" :selected="x.kind === 'practice'">練習</option>
                    <option value="party" :selected="x.kind === 'party'">コンパ</option>
                    <option value="etc" :selected="x.kind === 'etc'">その他</option>
                  </select>
                  <label class="mb-0 ml-auto mr-2">
                    <input type="checkbox" name="public" :checked="x.public">
                    公開
                  </label>
                </div>
                <div class="form-row align-items-center mt-3">
                  <input type="text" name="place" class="form-control col-9" placeholder="場所" :value="x.place">
                  <label class="col-3 mb-0">
                    <input type="checkbox" name="emph_place" :checked="x.emph_place">
                    強調
                  </label>
                </div>
                <div class="form-row align-items-center mt-3">
                  <label class="col-3 col-sm-2">
                    開始時刻
                    <input type="time" name="start_at" class="form-control" placeholder="hh:mm" :value="x.start_at">
                  </label>
                  <label class="col-3 col-sm-2 col-lg-1 mb-0">
                    <input type="checkbox" name="emph_start_at" :checked="x.emph_start_at">
                    強調
                  </label>
                  <label class="col-3 col-sm-2">
                    終了時刻
                    <input type="time" name="end_at" class="form-control" placeholder="hh:mm" :value="x.end_at">
                  </label>
                  <label class="col-3 col-sm-2 col-lg-1 mb-0">
                    <input type="checkbox" name="emph_end_at" :checked="x.emph_end_at">
                    強調
                  </label>
                </div>
                <div class="form-row mt-3">
                  <textarea name="description" class="form-control" :rows="rows" placeholder="備考" @input="autosizeTextarea($event.target)"/>
                </div>
                <div class="mt-3">
                  <button class="btn btn-success" @click="saveItem(x)">保存</button>
                  <button class="btn btn-danger" @click="removeItem(x)">削除</button>
                </div>
              </form>
              <hr>
            </template>
          </template>
          <template v-if="!gIsPublic">
            <div class="d-flex">
              <button ref="toggleEdit" class="btn ml-auto" :class="editing ? 'btn-outline-success' : 'btn-success'" data-toggle="collapse" data-target="#newScheduleForm" aria-expanded="false" @click="editing = !editing">
                {{ editing ? 'キャンセル' : '予定追加' }}
              </button>
            </div>
            <form id="newScheduleForm" class="collapse mt-3" @submit.prevent>
              <div class="form-row align-items-center">
                <input type="text" name="name" class="form-control col-9 col-sm-6" placeholder="タイトル" required>
                <label class="col mb-0">
                  <input type="checkbox" name="emph_name">
                  強調
                </label>
                <div class="d-block d-sm-none w-100 mt-3"/>
                <select type="text" name="kind" class="custom-select col-6 col-sm-2 mr-2">
                  <option value="practice" selected>練習</option>
                  <option value="party">コンパ</option>
                  <option value="etc">その他</option>
                </select>
                <label class="mb-0 ml-auto mr-2">
                  <input type="checkbox" name="public" checked>
                  公開
                </label>
              </div>
              <div class="form-row align-items-center mt-3">
                <input type="text" name="place" class="form-control col-9" placeholder="場所">
                <label class="col-3 mb-0">
                  <input type="checkbox" name="emph_place">
                  強調
                </label>
              </div>
              <div class="form-row align-items-center mt-3">
                <label class="col-3 col-sm-2">
                  開始時刻
                  <input type="time" name="start_at" class="form-control" placeholder="hh:mm">
                </label>
                <label class="col-3 col-sm-2 col-lg-1 mb-0">
                  <input type="checkbox" name="emph_start_at">
                  強調
                </label>
                <label class="col-3 col-sm-2">
                  終了時刻
                  <input type="time" name="end_at" class="form-control" placeholder="hh:mm">
                </label>
                <label class="col-3 col-sm-2 col-lg-1 mb-0">
                  <input type="checkbox" name="emph_end_at">
                  強調
                </label>
              </div>
              <div class="form-row mt-3">
                <textarea v-model="description" name="description" class="form-control" :rows="rows" placeholder="備考"/>
              </div>
              <div class="mt-3">
                <button class="btn btn-success" @click="addSchedule">保存</button>
              </div>
            </form>
          </template>
        </div>
      </div>
    </div>
  </div>
</template>
<script>
export default {
  data() {
    return {
      weekday_ja: $.util.weekday_ja,
      $dialog: null,
      detail: null,
      // 予定追加
      editing: false,
      description: null,
    };
  },
  computed: {
    rows() {
      return _.max([this.description && this.description.split('\n').length, 4]);
    },
  },
  mounted() {
    this.$dialog = $(this.$el);
  },
  methods: {
    open(year, month, day) {
      this.detail = {
        year: Number(year),
        month: Number(month),
        day: day.day,
        date: day.date,
        info: day.info,
        events: [],
        list: [],
      };
      this.$dialog.modal('show');
      this.fetch();
    },
    fetch() {
      axios.get(`/schedule/detail/${this.detail.year}-${this.detail.month}-${this.detail.date}`).then((res) => {
        this.detail.events = res.data.events;
        this.detail.list = _.map(res.data.list, (x) => {
          x.editing = false;
          return x;
        });
      }).catch(() => {
        this.$_notify('danger', '取得に失敗しました');
      });
    },
    openInfo(id) {
      this.$dialog.modal('hide');
      this.$emit('openinfo', id);
    },
    openComment(id) {
      this.$dialog.modal('hide');
      this.$emit('opencomment', id);
    },
    // 編集
    toggleEditItem(x) {
      x.editing = !x.editing;
      if (x.editing) {
        const $form = $(`#editForm${x.id}`);
        const $ta = $('textarea', $form);
        $ta.val(x.description);
        this.autosizeTextarea($ta);
      }
    },
    saveItem(x) {
      const $form = $(`#editForm${x.id}`);
      if (!$form.check()) return;
      let data = $form.serializeObject();
      data = _.mapValues(data, v => (v.trim() === '' ? null : v));
      axios.put(`/schedule/detail/item/${x.id}`, data).then(() => {
        this.fetch();
        this.$emit('done');
      }).catch(() => {
        this.$_notify('danger', '保存に失敗しました');
      });
    },
    removeItem(x) {
      axios.delete(`/schedule/detail/item/${x.id}`).then(() => {
        this.fetch();
        this.$emit('done');
      }).catch(() => {
        this.$_notify('danger', '削除に失敗しました');
      });
    },
    // 追加
    addSchedule() {
      const $form = $('#newScheduleForm');
      if (!$form.check()) return;
      let data = $form.serializeObject();
      data = _.mapValues(data, v => (v.trim() === '' ? null : v));
      data.year = this.detail.year;
      data.mon = this.detail.month;
      data.day = this.detail.date;
      axios.post('/schedule/detail/item', data).then(() => {
        this.$refs.toggleEdit.click();
        this.fetch();
        this.$emit('done');
      }).catch(() => {
        this.$_notify('danger', '保存に失敗しました');
      });
    },

    autosizeTextarea(tgt) {
      // textareaの行数を内容に合わせて変更
      const $ta = _.isElement(tgt) ? $(tgt) : tgt;
      $ta.attr('rows', _.max([$ta.val().split('\n').length, 4]));
    },
  },
};
</script>
<style lang="scss" scoped>
.emph {
  text-decoration: underline;
  font-weight: bold;
}
</style>
