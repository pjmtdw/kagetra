<template>
  <b-card class="shadow-sm" :class="thread.public ? 'border-primary' : 'private'" body-class="px-0 py-0">
    <template #header>
      <div class="d-flex align-items-center">
        <router-link :to="`/bbs/${thread.id}`" class="h6 text-dark text-decoration-none mb-0">{{ thread.title }}</router-link>
        <b-badge v-if="thread.public" variant="primary" class="ml-auto mr-1">外部公開</b-badge>
        <b-badge v-if="thread.has_new_comment" variant="success" class="mx-1">new</b-badge>
      </div>
    </template>
    <comment-list url="/bbs/item" :comments="thread.items" item-class="px-1 px-sm-3" @done="$emit('update')"/>
    <div>
      <b-button :variant="formOpened ? 'outline-success' : 'success'" class="my-2 ml-3" @click="formOpened = !formOpened">
        {{ formOpened ? 'キャンセル' : '書き込む' }}
      </b-button>
      <b-collapse :id="`newItemCollapse${thread.id}`" v-model="formOpened" @shown="$refs[`newItemForm${thread.id}`][0].focus()">
        <new-comment-form :ref="`newItemForm${thread.id}`" url="/bbs/item" :thread-id="thread.id" class="mx-3 mb-3 mt-2" @done="$emit('update'); formOpened = false"/>
      </b-collapse>
    </div>
  </b-card>
</template>
<script>
import { CommentList, NewCommentForm } from '@/containers';

export default {
  components: {
    CommentList,
    NewCommentForm,
  },
  props: {
    thread: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      formOpened: false,
    };
  },
};
</script>
<style lang="scss" scoped>
.private {
  border: 1px solid green;
  background-color: #FFD;
}
</style>
