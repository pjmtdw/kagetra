<template>
  <div class="d-flex flex-column flex-lg-row">
    <div>
      <h6 class="mb-1">
        <span>{{ event.name }}</span>
        <span class="place">@{{ event.place }}</span>
      </h6>
      <span class="ml-1 text-muted" v-html="timeRange(event.start_at, event.end_at)"/>
    </div>
    <div class="ml-auto">
      <b-button variant="info" @click="openInfo(event.id)">情報</b-button>
      <b-button v-if="isAuthenticated" variant="info" class="ml-2" @click="openComment(event.id)">コメント({{ event.comment_count }})</b-button>
    </div>
  </div>
</template>
<script>
import { timeRange, createVueInstance } from '@/utils';
import { EventInfoDialog, EventCommentDialog } from '@/containers';

export default {
  props: {
    event: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      timeRange,
    };
  },
  methods: {
    openInfo(id) {
      createVueInstance(EventInfoDialog).open(id);
    },
    openComment(id) {
      createVueInstance(EventCommentDialog).open(id);
    },
  },
};
</script>
<style lang="scss" scoped>
.place {
  color: #060;
}
</style>
