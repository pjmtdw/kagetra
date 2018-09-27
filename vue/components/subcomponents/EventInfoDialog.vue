<template>
  <div class="modal fade" tabindex="-1" role="dialog">
    <div class="modal-dialog modal-lg" role="document">
      <div v-if="id !== null" class="modal-content">
        <div class="modal-header d-flex flex-row align-items-center">
          <h5 class="font-weight-bold mb-0">{{ name }}</h5>
          <button v-if="editable" class="btn btn-success ml-auto" @click="openEdit">編集</button>
          <button class="btn btn-info ml-2" @click="openComment">コメント({{ comment_count }})</button>
        </div>
        <div class="modal-body">
          <div class="container">
            <div class="row">
              <div class="col-12 col-md-8">
                <div class="card mt-3">
                  <div class="card-header d-flex align-items-center justify-content-between">
                    <h6 class="mb-0"><strong>大会/行事名</strong></h6>
                  </div>
                  <div class="card-body">
                    {{ name }}
                    <span v-if="formal_name">({{ formal_name }})</span>
                  </div>
                </div>
              </div>
              <div class="col-12 col-md-4">
                <div class="card mt-3">
                  <h6 class="card-header"><strong>種別</strong></h6>
                  <div class="card-body">
                    <template v-if="kind === 'contest'">
                      <span v-if="official">公認</span><span v-else>非公認</span>
                      <span v-if="team_size === 1">個人戦</span><span v-else-if="team_size === 3">三人団体戦</span><span v-else-if="team_size === 5">五人団体戦</span>
                    </template>
                    <template v-else-if="kind === 'party'">
                      <span>コンパ/合宿/アフター等</span>
                    </template>
                    <template v-else-if="kind === 'etc'">
                      <span>アンケート/購入/その他</span>
                    </template>
                  </div>
                </div>
              </div>
            </div>
            <div class="row">
              <div class="col-12 col-md-6">
                <div class="card mt-3">
                  <h6 class="card-header"><strong>日時</strong></h6>
                  <div class="card-body">
                    <span>{{ date }}</span>
                    <span>({{ weekday }})</span>
                    <span v-html="$_timeRange(start_at, end_at)"/>
                  </div>
                </div>
              </div>
              <div class="col-12 col-md-6">
                <div class="card mt-3">
                  <h6 class="card-header"><strong>締切日</strong></h6>
                  <div class="card-body">
                    {{ deadline }}
                  </div>
                </div>
              </div>
            </div>
            <div class="row">
              <div class="col-12">
                <div class="card mt-3">
                  <h6 class="card-header"><strong>場所</strong></h6>
                  <div class="card-body">
                    {{ place }}
                  </div>
                </div>
              </div>
            </div>
            <div class="row">
              <div class="col">
                <div class="card mt-3">
                  <h6 class="card-header"><strong>備考</strong></h6>
                  <div class="card-body pre">{{ description }}</div>
                </div>
              </div>
            </div>
            <div class="row">
              <div class="col">
                <div class="card mt-3">
                  <h6 class="card-header"><strong>添付ファイル</strong></h6>
                  <div class="card-body">
                    <div v-for="f in attached" :key="f.id" class="mb-1">
                      <a :href="`/static/event/attached/${f.id}/${encodeURI(f.orig_name)}`" class="badge badge-light-shadow">
                        {{ f.orig_name }}
                      </a>
                      <p class="d-inline ml-2">{{ f.description }}</p>
                    </div>
                  </div>
                </div>
              </div>
            </div>
            <div v-for="c in positiveChoices" :key="c.id" class="row">
              <div class="col">
                <div class="card mt-3">
                  <h6 class="card-header"><strong>{{ c.name }}({{ countParticipant(participant[c.id]) }})</strong></h6>
                  <div class="card-body">
                    <template v-for="attr in participant_attrs">
                      <div v-if="participant[c.id][attr.id]" :key="attr.id" class="d-flex flex-row flex-wrap align-items-center mb-2">
                        <span class="badge badge-pill badge-primary">{{ attr.name }}</span>
                        <div v-for="pid in participant[c.id][attr.id]" :key="pid" class="ml-1 py-1">
                          <span class="member">{{ participant_names[pid] }}</span>
                        </div>
                      </div>
                    </template>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
<script>
export default {
  data() {
    return {
      $dialog: null,
      id: null,
      editable: null,
      comment_count: null,
      name: null,
      formal_name: null,
      kind: null,
      official: null,
      team_size: null,
      date: null,
      deadline: null,
      place: null,
      start_at: null,
      end_at: null,
      description: null,
      attached: null,
      choice: null,
      choices: null,
      participant: null,
      participant_attrs: null,
      participant_names: null,
    };
  },
  computed: {
    weekday() {
      return $.util.getWeekDay(this.date);
    },
    positiveChoices() {
      return _.filter(this.choices, c => c.positive);
    },
  },
  mounted() {
    this.$dialog = $(this.$el);
    this.$dialog.on('hide.bs.modal', () => this.$emit('close'));
    this.$dialog.on('shown.bs.modal', () => $('body').addClass('modal-open'));
  },
  methods: {
    open(id) {
      this.id = id;
      this.fetch();
    },
    fetch() {
      axios.get(`/event/item/${this.id}?detail=true`).then((res) => {
        this.$dialog.modal('show');
        _.each(res.data, (v, k) => {
          if (k === 'id') return;
          this[k] = v;
        });
      });
    },
    countParticipant(participants) {
      return _.sum(_.map(_.values(participants), v => v.length));
    },

    openComment() {
      this.$dialog.modal('hide');
      this.$emit('opencomment', this.id);
    },
    openEdit() {
      this.$dialog.modal('hide');
      this.$emit('openedit', { id: this.id, contest: this.kind === 'contest' });
    },
  },
};
</script>
<style lang="scss" scoped>
.member {
  border: 1px dotted #6c757d;
}
</style>
