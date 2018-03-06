<template>
  <div :id="id" class="modal fade" tabindex="-1" role="dialog" aria-hidden="true">
    <div class="modal-dialog modal-lg" role="document">
      <div class="modal-content">
        <div class="modal-header">
          <h5 v-if="add" class="modal-title">大会追加</h5>
          <h5 v-else class="modal-title">大会編集</h5>
          <button type="button" class="close" data-dismiss="modal" aria-label="Close">
            <span aria-hidden="true">&times;</span>
          </button>
        </div>
        <div v-show="loaded" class="modal-body">
          <form class="form-contest" @change="changed = true" @submit.prevent>
            <div class="form-row">
              <div class="form-group col-lg-4 col-sm-6">
                <label>
                  管理者(半角コンマ区切り)
                  <input type="text" name="owners_str" class="form-control" :value="owners_str" placeholder="管理者">
                </label>
                <div class="form-check d-inline-block">
                  <label>
                    <input type="checkbox" name="public" :checked="is_public">
                    <span>
                      公開
                    </span>
                  </label>
                  <span class="font-weight-bold ml-1" data-toggle="tooltip" data-placement="bottom" title="外部公開版の予定表や大会行事案内に表示されます．ただし登録者一覧およびコメントは公開されません．" >[?]</span>
                </div>
              </div>
            </div>
            <div class="form-row">
              <div class="form-group col-lg-4 col-sm-6">
                <label class="mb-1">
                  恒例大会
                  <select name="event_group_id" class="form-control">
                    <option value>---</option>
                    <option v-for="e in all_event_groups" :value="e.id" :selected="event_group_id === e.id">{{ e.name }}</option>
                  </select>
                </label>
                <button class="btn btn-outline-success mb-1" type="button" @click="add_event_group">追加</button>
              </div>
              <div class="form-group col-lg-4 col-sm-6">
                <label>
                  大会/行事名
                  <input type="text" name="name" class="form-control" placeholder="大会/行事名" :value="name">
                </label>
              </div>
              <div class="form-group col-lg-4 col-sm-6">
                <label>
                  正式名称
                  <input type="text" name="formal_name" class="form-control" placeholder="正式名称" :value="formal_name">
                </label>
              </div>
              <div class="form-group col-lg-4 col-sm-3 col-6">
                <label>
                  公認/非公認
                  <select name="official" class="form-control">
                    <option value="true" :selected="official">公認</option>
                    <option value="false" :selected="!official">非公認</option>
                  </select>
                </label>
              </div>
              <div class="form-group col-lg-4 col-sm-3 col-6">
                <label>
                  個人戦/団体戦
                  <select name="team_size" class="form-control">
                    <option value="1" :selected="team_size === 1">個人戦</option>
                    <option value="3" :selected="team_size === 3">三人団体戦</option>
                    <option value="5" :selected="team_size === 5">五人団体戦</option>
                  </select>
                </label>
              </div>
            </div>
            <div class="form-row">
              <div class="form-group col-lg-4 col-12">
                <label class="w-100">
                  場所
                  <input type="text" class="form-control w-100" name="place" placeholder="場所" :value="place">
                </label>
              </div>
              <div class="form-group col-lg-3 col-sm-4 col-12">
                <label>
                  開催日
                  <input type="date" class="form-control" name="date" placeholder="YYYY-MM-DD" :value="date">
                </label>
              </div>
              <div class="form-group col-sm-2 col-6">
                <label>
                  開始時刻
                  <input type="time" class="form-control" name="start_at" placeholder="hh:mm" :value="start_at">
                </label>
              </div>
              <div class="form-group col-sm-2 col-6">
                <label>
                  終了時刻
                  <input type="time" class="form-control" name="end_at" placeholder="hh:mm" :value="end_at">
                </label>
              </div>
            </div>
            <div class="form-group">
              <label class="w-100">
                備考
                <textarea name="description" class="form-control" :rows="rows"
                          v-model="description" placeholder="備考"/>
              </label>
            </div>
          </form>
          <div v-if="!add" class="card border-0 bg-light">
            <div class="card-body">
              <h5 class="card-title">添付ファイル</h5>
              <div v-for="f in attached" :key="f.id">
                <a :href="`/static/event/attached/${f.id}/${encodeURI(f.orig_name)}`" class="badge badge-light-shadow">{{ f.orig_name }}</a>
                <p class="d-inline ml-2">{{ f.description }}</p>
              </div>
              <div class="mt-3"/>
              <file-post :id="add ? 0 : contest_id" namespace="event" @done="submit_file_done"/>
            </div>
          </div>
        </div>
        <div class="modal-footer">
          <button v-if="!add" type="button" class="btn btn-danger mr-auto" @click="delete_event">削除</button>
          <button type="button" class="btn btn-outline-secondary" data-dismiss="modal">キャンセル</button>
          <button type="button" class="btn btn-success" @click="edit_event" :disabled="!loaded">保存</button>
        </div>
      </div>
    </div>
  </div>
</template>
<script>
/* global g_user_name */
export default {
  props: {
    id: {
      type: String,
      default: null,
    },
    contest_id: {
      type: Number,
      default: null,
    },
    editing: {
      type: Boolean,
      default: false,
    },
  },
  data() {
    return {
      loaded: false,
      user_name: g_user_name,
      changed: false,
      submitting: {},
      // edit
      attached: [],
      name: '',
      formal_name: '',
      owners_str: '',
      is_public: true,
      event_group_id: -1,
      all_event_groups: [],
      official: true,
      team_size: 1,
      date: '',
      start_at: '',
      end_at: '',
      place: '',
      description: '',
    };
  },
  computed: {
    add() {
      return this.contest_id === null;
    },
    rows() {
      return _.max([this.description.split('\n').length, 4]);
    },
  },
  mounted() {
    $(this.$el).on('show.bs.modal', () => {
      this.fetch_edit();
    }).on('hide.bs.modal', (e) => {
      if (!this.changed) {
        this.$emit('done');
        return;
      }
      e.preventDefault();
      $.confirm('本当に変更を破棄して閉じますか？').then(() => {
        this.changed = false;
        $(this.$el).modal('hide');
      }).catch(() => {
        $('body').addClass('modal-open');
      });
    });
  },
  methods: {
    fetch_edit() {
      const url = `/api/event/item/${this.add ? 'contest' : this.contest_id}?detail=true&edit=true`;
      axios.get(url).then((res) => {
        _.forEach(res.data, (v, key) => {
          if (key === 'id') {
            // do nothing
          } else if (key === 'public') {  // public is reserved
            this.is_public = v;
          } else {
            this[key] = v;
          }
        });
        this.loaded = true;
      }).catch(() => {
        $.notify('danger', '情報の取得に失敗しました');
      });
    },
    fetch_edit_attached() {
      const url = `/api/event/item/${this.add ? 'contest' : this.contest_id}?detail=true&edit=true`;
      axios.get(url).then((res) => {
        this.attached = res.data.attached;
      }).catch(() => {
        $.notify('danger', '情報の取得に失敗しました');
      });
    },
    edit_event() {
      let data = $('form.form-contest', this.$el).serializeObject();
      data = _.mapValues(data, v => (v.trim() === '' ? null : v));
      const url = `/api/event/item/${this.contest_id}`;
      const onSave = () => {
        $.notify('success', '保存しました');
        this.changed = false;
        $(this.$el).modal('hide');
        this.$emit('done');
      };
      if (!this.changed) {
        onSave();
        return;
      }
      axios.put(url, data).then(onSave).catch(() => {
        $.notify('danger', '保存に失敗しました');
      });
    },
    delete_event() {
      $.confirm('本当に削除していいですか？').then(() => {
        axios.delete(`/api/event/item/${this.contest_id}`).then(() => {
          $.notify('success', '削除しました');
          $(this.$el).modal('hide');
          location.href = '/result#/';
        }).catch(() => {
          $.notify('danger', '削除に失敗しました');
        });
      }).catch(() => {
        $('body').addClass('modal-open');
      });
    },
    add_event_group() {
      $.inputDialog('追加する恒例大会名').then((name) => {
        axios.post('/api/event/group/new', { name }).then(() => {
          $.notify('success', '追加しました');
          this.fetch_edit();
        }).catch(() => {
          $.notify('danger', '追加に失敗しました');
        });
      }).always(() => {
        $('body').addClass('modal-open');
      });
    },
    submit_file_done() {
      this.fetch_edit_attached();
    },
  },
};
</script>
<style lang="scss" scoped>
@import '../sass/common.scss';
.card {
  box-shadow: 1px 2px 4px rgba(black, 0.1);
}
</style>
