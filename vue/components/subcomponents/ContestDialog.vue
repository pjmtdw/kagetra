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
                  <input :value="owners_str" type="text" name="owners_str" class="form-control" placeholder="管理者">
                </label>
                <div class="form-check d-inline-block">
                  <label>
                    <input v-model="is_public" type="checkbox" name="public">
                    <span data-toggle="tooltip" data-placement="bottom" title="外部公開版の予定表や大会行事案内に表示されます．ただし登録者一覧およびコメントは公開されません．">
                      公開
                    </span>
                  </label>
                </div>
              </div>
            </div>
            <div class="form-row">
              <div class="form-group col-lg-4 col-sm-6">
                <!-- <label class="mb-2">
                  恒例大会
                  <select v-model="event_group_id" name="event_group_id" class="form-control" @change="fetchPastList">
                    <option value="-1">---</option>
                    <option v-for="e in all_event_groups" :key="e.id" :value="e.id">
                      {{ e.name }}
                    </option>
                  </select>
                </label>
                <button class="btn btn-outline-success mb-2" type="button" @click="addEventGroup">追加</button> -->
                <label for="event_group_id_select" class="mb-0">恒例大会</label>
                <div class="input-group">
                  <div class="input-group-prepend">
                    <button class="btn btn-outline-success" type="button" @click="addEventGroup">追加</button>
                  </div>
                  <select id="event_group_id_select" name="event_group_id" class="custom-select">
                    <option value="-1">---</option>
                    <option v-for="e in all_event_groups" :key="e.id" :value="e.id">
                      {{ e.name }}
                    </option>
                  </select>
                </div>
              </div>
              <div v-if="add" class="form-group col-sm-4">
                <label class="mb-1 w-100">
                  情報コピー
                  <select v-model="copyFrom" name="copy_from" class="form-control" @change="copyPast">
                    <option v-if="pastContests.length" selected>---</option>
                    <option v-for="c in pastContests" :key="c.id" :value="c.id">{{ c.date }} {{ c.name }}</option>
                  </select>
                </label>
              </div>
              <div v-if="add" class="w-100 d-none d-lg-block"/>
              <div class="form-group col-lg-4 col-sm-6">
                <label class="w-100">
                  大会/行事名
                  <input :value="name" type="text" name="name" class="form-control" placeholder="大会/行事名">
                </label>
              </div>
              <div class="form-group col-lg-4 col-sm-6">
                <label class="w-100">
                  正式名称
                  <input v-model="formal_name" type="text" name="formal_name" class="form-control" placeholder="正式名称">
                </label>
              </div>
              <div v-if="add" class="w-100 d-none d-lg-block"/>
              <div class="form-group col-lg-4 col-sm-3 col-6">
                <label>
                  公認/非公認
                  <select v-model="official" name="official" class="form-control">
                    <option value="true">公認</option>
                    <option value="false">非公認</option>
                  </select>
                </label>
              </div>
              <div class="form-group col-lg-4 col-sm-3 col-6">
                <label>
                  個人戦/団体戦
                  <select v-model="team_size" name="team_size" class="form-control">
                    <option value="1">個人戦</option>
                    <option value="3">三人団体戦</option>
                    <option value="5">五人団体戦</option>
                  </select>
                </label>
              </div>
            </div>
            <div class="form-row">
              <div class="form-group col-lg-4 col-12">
                <label class="w-100">
                  場所
                  <input v-model="place" type="text" class="form-control w-100" name="place" placeholder="場所">
                </label>
              </div>
              <div class="form-group col-lg-3 col-sm-4 col-12">
                <label>
                  開催日
                  <input v-model="date" type="date" class="form-control" name="date" placeholder="YYYY-MM-DD">
                </label>
              </div>
              <div class="form-group col-sm-2 col-6">
                <label>
                  開始時刻
                  <input v-model="start_at" type="time" class="form-control" name="start_at" placeholder="hh:mm">
                </label>
              </div>
              <div class="form-group col-sm-2 col-6">
                <label>
                  終了時刻
                  <input v-model="end_at" type="time" class="form-control" name="end_at" placeholder="hh:mm">
                </label>
              </div>
            </div>
            <div class="form-group">
              <label class="w-100">
                備考
                <textarea v-model="description" name="description" class="form-control" :rows="rows" placeholder="備考"/>
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
              <file-post :id="add ? 0 : contestId" namespace="event" @done="submitFileDone"/>
            </div>
          </div>
        </div>
        <div class="modal-footer">
          <button v-if="!add" type="button" class="btn btn-danger mr-auto" @click="deleteEvent">削除</button>
          <button type="button" class="btn btn-outline-secondary" data-dismiss="modal">キャンセル</button>
          <button type="button" class="btn btn-success" :disabled="!loaded" @click="editEvent">保存</button>
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
    contestId: {
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
      userName: g_user_name,
      changed: false,
      submitting: {},
      // info copy
      pastContests: [],
      copyFrom: null,
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
      return this.contestId === null;
    },
    rows() {
      return _.max([this.description.split('\n').length, 4]);
    },
  },
  mounted() {
    $(this.$el).on('show.bs.modal', () => {
      this.fetchEdit();
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
    fetchEdit() {
      const url = `/api/event/item/${this.add ? 'contest' : this.contestId}?detail=true&edit=true`;
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
    fetchEditAttached() {
      const url = `/api/event/item/${this.add ? 'contest' : this.contestId}?detail=true&edit=true`;
      axios.get(url).then((res) => {
        this.attached = res.data.attached;
      }).catch(() => {
        $.notify('danger', '情報の取得に失敗しました');
      });
    },
    fetchPastList() {
      if (!this.add) return;
      axios.get(`/api/event/group_list/${this.event_group_id}`).then((res) => {
        this.pastContests = res.data;
      });
    },
    copyPast() {
      axios.get(`/api/event/item/${this.copyFrom}?detail=true&edit=true`).then((res) => {
        const d = res.data;
        this.is_public = d.public;
        this.name = d.name;
        this.formal_name = d.formal_name;
        this.official = d.official;
        this.team_size = d.team_size;
        this.date = d.date;
        this.start_at = d.start_at;
        this.end_at = d.end_at;
        this.place = d.place;
        this.description = d.description || '';
      });
    },
    editEvent() {
      let data = $('form.form-contest', this.$el).serializeObject();
      data = _.mapValues(data, v => (v.trim() === '' ? null : v));
      const url = `/api/event/item/${this.contestId}`;
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
    deleteEvent() {
      $.confirm('本当に削除していいですか？').then(() => {
        axios.delete(`/api/event/item/${this.contestId}`).then(() => {
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
    addEventGroup() {
      $.inputDialog('追加する恒例大会名').then((name) => {
        axios.post('/api/event/group/new', { name }).then(() => {
          $.notify('success', '追加しました');
          this.fetchEdit();
        }).catch(() => {
          $.notify('danger', '追加に失敗しました');
        });
      }).always(() => {
        $('body').addClass('modal-open');
      });
    },
    submitFileDone() {
      this.fetchEditAttached();
    },
  },
};
</script>
<style lang="scss" scoped>
@import '../../sass/common.scss';
.card {
  box-shadow: 1px 2px 4px rgba(black, 0.1);
}
</style>
