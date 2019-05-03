<template>
  <b-list-group flush>
    <b-list-group-item v-for="item in comments" :key="item.id" class="bg-transparent" :class="itemClass">
      <div v-if="!item.editing" class="d-flex">
        <span class="name">{{ item.user_name }}</span>
        <span class="date">@{{ item.date }}</span>
        <h6 v-if="item.is_new" class="align-self-center"><b-badge variant="success" class="mx-1">new</b-badge></h6>
        <b-button v-if="item.editable" variant="outline-success" size="sm" class="ml-auto" @click="toggleEditItem(item)">
          編集
        </b-button>
      </div>
      <div v-show="!item.editing" class="pre mt-1 pl-2" v-html="replaceLink(item.body)"/>
      <v-form v-if="item.editable" v-show="item.editing" :ref="`editForm${item.id}`" @keydown.shift.enter="editItem(item)">
        <div class="d-flex align-items-center mb-2">
          <v-field class="d-flex align-items-center mb-0 mr-1" feedback="名前を入力してください">
            <v-input v-model="item.nameInput" class="d-inline" placeholder="名前" required/>
            <span class="date ml-1 d-none d-sm-inline text-nowrap">@{{ item.date }}</span>
          </v-field>
          <b-button variant="outline-success text-nowrap" size="sm" class="ml-auto" @click="toggleEditItem(item)">
            キャンセル
          </b-button>
        </div>
        <v-field feedback="内容を入力してください">
          <v-textarea :ref="`bodyInput${item.id}`" v-model="item.bodyInput" rows="4" placeholder="内容" required/>
        </v-field>
        <div class="d-flex">
          <b-button variant="danger" class="ml-auto mr-2" @click="deleteItem(item)">削除</b-button>
          <b-button variant="success" @click="editItem(item)">保存</b-button>
        </div>
      </v-form>
    </b-list-group-item>
  </b-list-group>
</template>
<script>
import { replace } from 'lodash';
import { escapeHtml } from '@/utils';
import { VForm } from '@/components';

export default {
  components: {
    VForm,
  },
  props: {
    comments: {
      type: Array,
      required: true,
    },
    url: {
      type: String,
      required: true,
    },
    itemClass: {
      type: String,
      default: null,
    },
  },
  methods: {
    toggleEditItem(item) {
      const form = this.$refs[`editForm${item.id}`][0];
      if (item.editing) {
        form.reset();
      } else {
        this.$set(item, 'nameInput', item.user_name);
        this.$set(item, 'bodyInput', item.body);
        this.$nextTick(() => {
          this.$nextTick(this.$refs[`bodyInput${item.id}`][0].focus);
        });
      }
      this.$set(item, 'editing', !item.editing);
    },
    editItem(item) {
      const form = this.$refs[`editForm${item.id}`][0];
      if (!form.validate()) return;
      const data = {
        user_name: item.nameInput,
        body: item.bodyInput,
      };
      this.$http.put(`${this.url}/${item.id}`, data).then(() => {
        this.toggleEditItem(item);
        form.reset();
        this.$emit('done');
      });
    },
    deleteItem(item) {
      this.$confirm('この投稿を削除してよろしいですか？').then(() => {
        this.$http.delete(`${this.url}/${item.id}`).then(() => {
          this.$emit('done');
        });
      });
    },
    replaceLink(str) {
      const regUrl = new RegExp('(https?://[a-zA-Z0-9/:%#$&?()~.=+_-]+)', 'gi');
      /* eslint-disable-next-line no-useless-escape */
      const regMail = new RegExp('(([*+!.&#\$|\'\\%\/0-9a-z^_`{}=?~:-]+)@(([0-9a-z-]+\.)+[0-9a-z]{2,}))', 'gi');
      const replaceUrlToLink = text => replace(text, regUrl, '<a href="$1">$1</a>');
      const replaceMailToLink = text => replace(text, regMail, '<a href="mailto:$1">$1</a>');
      return replaceMailToLink(replaceUrlToLink(escapeHtml(str)));
    },
  },
};
</script>
<style lang="scss" scoped>
.name {
  color: #040;
}
.date {
  color: brown;
}
</style>
