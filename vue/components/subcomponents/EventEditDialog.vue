<template>
  <div class="modal fade" tabindex="-1" role="dialog">
    <div class="modal-dialog modal-lg" role="document">
      <div v-if="id !== null" class="modal-content">
        <div class="modal-header">
          <h5 class="modal-title">
            {{ contest ? '大会' : '行事' }}{{ add ? '追加' : '編集' }}
          </h5>
          <button type="button" class="close" data-dismiss="modal" aria-label="Close">
            <span aria-hidden="true">&times;</span>
          </button>
        </div>
        <div class="modal-body">
          <!-- タブ -->
          <nav v-if="!add" class="nav nav-pills mb-3">
            <a class="nav-item nav-link" :class="{ active: tab === 'info' }" href="#" @click.prevent="tab = 'info'">
              情報
            </a>
            <a v-if="!done" class="nav-item nav-link" :class="{ active: tab === 'participant' }" href="#" @click.prevent="tab = 'participant'">
              登録者
            </a>
            <a class="nav-item nav-link" :class="{ active: tab === 'attach' }" href="#" @click.prevent="tab = 'attach'">
              添付ファイル
            </a>
          </nav>
          <!-- タブの中 -->
          <div class="tab-content">
            <!-- 情報 -->
            <div class="tab-pane" :class="{ 'show active': tab === 'info' }">
              <form ref="form" class="form-contest jumbotron bg-light shadow-sm p-3" @input="changed = true" @submit.prevent @keydown.shift.enter="editEvent">
                <div class="form-row">
                  <div class="form-group col-lg-4 col-sm-6">
                    <label>
                      管理者(半角コンマ区切り)
                      <input v-model="owners_str" type="text" name="owners_str" class="form-control" placeholder="管理者">
                    </label>
                    <div class="form-check d-inline-block">
                      <label>
                        <input v-model="is_public" type="checkbox" name="public">
                        <span>
                          公開
                        </span>
                        <TooltipIcon placement="bottom" title="外部公開版の予定表や大会行事案内に表示されます．ただし登録者一覧およびコメントは公開されません．"/>
                      </label>
                    </div>
                  </div>
                </div>
                <div class="form-row">
                  <div v-if="contest" class="form-group col-lg-4 col-sm-6">
                    <label for="event_group_id_select" class="mb-0">恒例大会</label>
                    <div class="input-group">
                      <div class="input-group-prepend">
                        <button class="btn btn-outline-success" type="button" @click="addEventGroup">追加</button>
                      </div>
                      <select v-model="event_group_id" id="event_group_id_select" name="event_group_id" class="custom-select" @change="fetchPastList">
                        <option value="-1">---</option>
                        <option v-for="eg in all_event_groups" :key="eg.id" :value="eg.id">
                          {{ eg.name }}
                        </option>
                      </select>
                    </div>
                  </div>
                  <div v-else class="form-group col-lg-4 col-sm-6">
                    <label for="event_kind_select" class="mb-0">種別</label>
                    <select v-model="kind" id="event_kind_select" name="kind" class="custom-select">
                      <option value="party">コンパ/合宿/アフター等</option>
                      <option value="etc">アンケート/購入/その他</option>
                    </select>
                  </div>
                  <div v-if="add && contest" class="form-group col-sm-4">
                    <label class="mb-1 w-100">
                      情報コピー
                      <select v-model="copyFrom" name="copy_from" class="form-control" :disabled="pastContests.length === 0" @change="copyPast">
                        <option v-if="pastContests.length" value="-1">---</option>
                        <option v-for="c in pastContests" :key="c.id" :value="c.id">{{ c.date }} {{ c.name }}</option>
                      </select>
                    </label>
                  </div>
                  <div v-if="add && contest" class="w-100 d-none d-lg-block"/>
                  <div class="form-group col-lg-4 col-sm-6">
                    <label class="w-100">
                      大会/行事名
                      <input v-model="name" type="text" name="name" class="form-control" placeholder="大会/行事名" required>
                      <div class="invalid-feedback">この項目は必須です</div>
                    </label>
                  </div>
                  <div v-if="contest" class="form-group col-lg-4 col-sm-6">
                    <label class="w-100">
                      正式名称
                      <input v-model="formal_name" type="text" name="formal_name" class="form-control" placeholder="正式名称">
                    </label>
                  </div>
                </div>
                <div v-if="contest" class="form-row">
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
                <div v-if="!done" class="form-row">
                  <div class="form-group col-lg-3 col-sm-4 col-12">
                    <label>
                      締切日
                      <input v-model="deadline" type="date" class="form-control" name="deadline" placeholder="YYYY-MM-DD">
                    </label>
                  </div>
                  <div class="form-group col-lg-3 col-sm-4 col-12">
                    <label>
                      集計属性
                      <select v-model="aggregate_attr_id" name="aggregate_attr_id" class="custom-select">
                        <option v-for="attr in all_attrs" :key="attr.id" :value="attr.id">{{ attr.name }}</option>
                      </select>
                    </label>
                  </div>
                </div>
                <div v-if="!done" class="form-row">
                  <div v-if="contest" class="form-group col-12 col-md-6">
                    <label class="mb-0">参加不能属性</label>
                    <div class="d-flex flex-row flex-wrap align-items-center">
                      <div v-for="aid in forbidden_attrs" :key="aid" class="py-1 ml-1">
                        <div class="forbidden-attr">
                          <span class="align-middle">{{ attr_values[aid].attr.name }}: {{ attr_values[aid].value }}</span>
                          <span class="close d-inline align-top" @click="removeForbiddenAttr(aid)">&times;</span>
                        </div>
                      </div>
                      <div class="dropdown">
                        <button type="button" class="btn btn-success btn-sm dropdown-toggle ml-1" data-toggle="dropdown" data-boundary="window" data-flip="false" aria-haspopup="true" aria-expanded="false">
                          追加
                        </button>
                        <div class="dropdown-menu">
                          <template v-for="attr in addableAttrs">
                            <h6 class="dropdown-header">{{ attr.name }}</h6>
                            <a v-for="v in attr.values" href="#" class="dropdown-item" @click.prevent="addForbiddenAttr(v.id)">{{ v.value }}</a>
                            <div class="dropdown-divider"/>
                          </template>
                        </div>
                      </div>
                    </div>
                  </div>
                  <div class="form-group col-12 col-md-6">
                    <label class="mb-0">選択肢</label>
                    <div class="d-flex flex-row flex-wrap align-items-center">
                      <div v-for="c in choices" class="py-1 ml-1">
                        <div class="choice" :class="{ positive: c.positive }">
                          <span class="align-middle cursor-pointer" @click="editChoice(c)">{{ c.name }}</span>
                          <span v-if="c.positive" class="close d-inline align-top" @click="removeChoice(c)">&times;</span>
                        </div>
                      </div>
                      <button type="button" class="btn btn-success btn-sm ml-1" @click="addChoice">追加</button>
                    </div>
                  </div>
                </div>
                <div v-if="!done" class="form-row">
                  <div v-if="contest" class="form-group col">
                    <label class="mr-3">
                      <input type="checkbox" name="hide_choice">
                      選択結果を隠す
                      <TooltipIcon title="誰がどの選択肢を選んだかを管理者以外には分からないようにします．Tシャツ注文のサイズなどのプライバシーの保護にお使い下さい．"/>
                    </label>
                    <label>
                      <input type="checkbox" name="register_done">
                      登録者確認済
                      <TooltipIcon title="「締切を過ぎました」に表示されなくなります．"/>
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
            </div>
            <!-- 登録者 -->
            <div v-if="!add && !done" class="tab-pane" :class="{ 'show active': tab === 'participant' }">
              <div class="jumbotron bg-light shadow-sm p-3">
                登録者
              </div>
            </div>
            <!-- 添付ファイル -->
            <div v-if="!add" class="tab-pane" :class="{ 'show active': tab === 'attach' }">
              <div class="jumbotron bg-light shadow-sm p-3">
                <div v-for="f in attached" :key="f.id">
                  <a :href="`/static/event/attached/${f.id}/${encodeURI(f.orig_name)}`" class="badge badge-light-shadow">{{ f.orig_name }}</a>
                  <p class="d-inline ml-2">{{ f.description }}</p>
                </div>
                <div class="mt-3"/>
                <FilePost :id="id" namespace="event" @done="submitFileDone"/>
              </div>
            </div>
          </div>
        </div>
        <div v-if="tab === 'info'" class="modal-footer">
          <button v-if="!add" type="button" class="btn btn-danger mr-auto" @click="deleteEvent">削除</button>
          <button type="button" class="btn btn-outline-secondary" data-dismiss="modal">キャンセル</button>
          <button type="button" class="btn btn-success" @click="editEvent">保存</button>
        </div>
        <div v-else-if="tab === 'participant'" class="modal-footer">
          <button type="button" class="btn btn-success ml-auto" @click="editParticipant">保存</button>
        </div>
      </div>
    </div>
  </div>
</template>
<script>
import FilePost from './FilePost.vue';

export default {
  components: {
    FilePost,
  },
  props: {
    hideAttr: {
      type: Boolean,
      default: false,
    },
  },
  data() {
    return {
      $dialog: null,
      contest: null,  // Boolean, party/etc if false
      id: null,
      changed: false,
      tab: 'info',

      // info
      done: null,

      // etc
      pastContests: [],
      copyFrom: null,
      all_attrs: null,

      // edit
      name: null,
      formal_name: null,
      owners_str: null,
      is_public: true,

      event_group_id: -1,
      all_event_groups: null,
      official: true,
      team_size: 1,

      kind: null,

      date: null,
      start_at: null,
      end_at: null,
      place: null,
      description: null,

      deadline: null,
      aggregate_attr_id: null,
      choices: null,
      forbidden_attrs: null,

      attached: null,
    };
  },
  computed: {
    add() {
      return _.isNil(this.id);
    },
    rows() {
      return _.max([this.description && this.description.split('\n').length, 4]);
    },
    attr_values() {
      const ret = {};
      _.each(this.all_attrs, (attr) => {
        _.each(attr.values, (v) => {
          ret[v.id] = { attr, value: v.value };
        });
      });
      return ret;
    },
    addableAttrs() {
      const ret = _.cloneDeep(this.all_attrs);
      _.each(ret, (attr) => {
        _.remove(attr.values, v => _.includes(this.forbidden_attrs, v.id));
      });
      return _.filter(ret, attr => attr.values.length > 0);
    },
  },
  mounted() {
    this.$dialog = $(this.$el);
    this.$dialog.on('hide.bs.modal', () => this.$emit('close'));
    this.$dialog.on('shown.bs.modal', () => $('body').addClass('modal-open'));
    this.$dialog.on('hide.bs.modal', (e) => {
      if (!this.changed) {
        this.reset();
        return;
      }
      e.preventDefault();
      this.$_confirm('本当に変更を破棄して閉じますか？').then(() => {
        this.changed = false;
        $(this.$el).modal('hide');
      }).catch(() => {
        $('body').addClass('modal-open');
      });
    });
    this.$_setBeforeUnload(() => this.changed);
  },
  methods: {
    open(data) {
      this.id = data.id;
      this.contest = data.contest;
      if (this.add && !this.contest) this.kind = 'party';
      this.fetch();
    },
    fetch() {
      const kind = this.contest ? 'contest' : 'party';
      axios.get(`/event/item/${this.add ? kind : this.id}?detail=true&edit=true`).then((res) => {
        this.$dialog.modal('show');
        _.each(res.data, (v, k) => {
          if (k === 'public') this.is_public = v;
          else this[k] = v;
        });
      }).catch(() => {
        this.$_notify('danger', '情報の取得に失敗しました');
      });
    },
    fetchPastList() {
      if (!this.add) return;
      axios.get(`/event/group_list/${this.event_group_id}`).then((res) => {
        this.pastContests = res.data;
        this.copyFrom = -1;
      }).catch(() => {
        this.$_notify('danger', '情報の取得に失敗しました');
      });
    },
    fetchEditAttached() {
      const url = `/event/item/${this.id}?detail=true&edit=true`;
      axios.get(url).then((res) => {
        this.attached = res.data.attached;
      }).catch(() => {
        this.$_notify('danger', '情報の取得に失敗しました');
      });
    },
    reset() {
      this.contest = null;
      this.id = null;
      this.changed = false;
      this.tab = 'info';
      this.done = null;
      this.pastContests = [];
      this.copyFrom = null;
      this.all_attrs = null;
      this.name = null;
      this.formal_name = null;
      this.owners_str = null;
      this.is_public = true;
      this.event_group_id = -1;
      this.all_event_groups = null;
      this.official = true;
      this.team_size = 1;
      this.kind = null;
      this.date = null;
      this.start_at = null;
      this.end_at = null;
      this.place = null;
      this.description = null;
      this.deadline = null;
      this.aggregate_attr_id = null;
      this.choices = null;
      this.forbidden_attrs = null;
      this.attached = null;
    },

    // 情報
    copyPast() {
      axios.get(`/event/item/${this.copyFrom}?detail=true&edit=true`).then((res) => {
        this.is_public = res.data.public;
        const keys = ['name', 'formal_name', 'official', 'team_size', 'start_at', 'end_at',
          'place', 'description', 'forbidden_attrs', 'aggregate_attr_id'];
        _.each(keys, (k) => {
          this[k] = res.data[k];
        }).catch(() => {
          this.$_notify('danger', '情報の取得に失敗しました');
        });
      });
    },
    addEventGroup() {
      this.$_prompt('追加する恒例大会名').then((name) => {
        axios.post('/event/group/new', { name }).then(() => {
          this.fetchEdit();
        }).catch(() => {
          this.$_notify('danger', '追加に失敗しました');
        });
      }).always(() => {
        $('body').addClass('modal-open');
      });
    },
    addForbiddenAttr(attrId) {
      this.changed = true;
      this.forbidden_attrs.push(attrId);
    },
    removeForbiddenAttr(attrId) {
      this.changed = true;
      this.$delete(this.forbidden_attrs, _.indexOf(this.forbidden_attrs, attrId));
    },
    addChoice() {
      this.changed = true;
      this.$_prompt('選択肢名').then((name) => {
        this.choices.splice(-1, 0, {
          id: -1,
          name,
          positive: true,
        });
      }).always(() => {
        $('body').addClass('modal-open');
      });
    },
    editChoice(choice) {
      this.changed = true;
      this.$_prompt('選択肢名', choice.name).then((name) => {
        choice.name = name;
      }).always(() => {
        $('body').addClass('modal-open');
      });
    },
    removeChoice(choice) {
      this.changed = true;
      this.$delete(this.choices, _.indexOf(this.choices, choice));
    },
    getData() {
      const $form = $(this.$refs.form);
      let data = $form.serializeObject();
      data = _.omit(data, 'copy_from');
      data = _.mapValues(data, v => ((_.isString(v) && v.trim() === '') ? null : v));
      if (data.event_group_id === '-1') data.event_group_id = null;
      if (this.contest) {
        data.kind = 'contest';
        data.forbidden_attrs = this.forbidden_attrs;
      }
      data.choices = this.choices;
      return data;
    },
    addEvent() {
      if (!$(this.$refs.form).check()) return;
      const data = this.getData();
      const onSave = (res) => {
        this.changed = false;
        this.$dialog.modal('hide');
        if (!_.isUndefined(res)) this.$emit('done', res.data);
        else this.$emit('done');
      };
      if (!this.changed) {
        onSave();
        return;
      }
      axios.post('/event/item', data).then(onSave).catch(this.$_makeOnFail('追加に失敗しました'));
    },
    editEvent() {
      if (this.add) {
        this.addEvent();
        return;
      }
      if (!$(this.$refs.form).check()) return;
      const data = this.getData();
      const onSave = () => {
        this.changed = false;
        this.$dialog.modal('hide');
        this.$emit('done');
      };
      if (!this.changed) {
        onSave();
        return;
      }
      axios.put(`/event/item/${this.id}`, data).then(onSave).catch(this.$_makeOnFail('保存に失敗しました'));
    },
    deleteEvent() {
      this.$_confirm('本当に削除していいですか？').then(() => {
        axios.delete(`/event/item/${this.id}`).then(() => {
          this.$dialog.modal('hide');
          if (this.gRouteName === 'result') this.$router.push('/');
        }).catch(() => {
          this.$_notify('danger', '削除に失敗しました');
        });
      }).catch(() => {
        $('body').addClass('modal-open');
      });
    },

    // 登録者
    editParticipant() {

    },

    // 添付ファイル
    submitFileDone() {
      this.fetchEditAttached();
    },
  },
};
</script>
<style lang="scss" scoped>
.choice {
  border: 1px dotted rgba(0, 0, 0, .6);
  &.positive {
    background-color: #ffd;
  }
  &:not(.positive) {
    background-color: rgba(0, 0, 0, .07);
  }
}
.forbidden-attr {
  border: 1px dotted rgba(0, 0, 0, .6);
  background-color: rgba(0, 0, 0, .07);
}
.dropdown {
  .dropdown-divider:last-child {
    display: none;
  }
  .dropdown-menu {
    height: 200px;
    overflow-y: auto;
  }
}
</style>
