/**
< !--dialog -->
<DayDetailDialog ref="detailDialog" @openinfo="openInfo" @opencomment="openComment" />
<EventInfoDialog ref="infoDialog" @openedit="openEdit" @opencomment="openComment" />
<EventEditDialog ref="editDialog" @done="fetch" />
<EventCommentDialog ref="commentDialog" @openinfo="openInfo" />
 */
import DayDetailDialog from './DayDetailDialog.vue';
import EventInfoDialog from './EventInfoDialog.vue';
import EventEditDialog from './EventEditDialog.vue';
import EventCommentDialog from './EventCommentDialog.vue';

export default {
  components: {
    DayDetailDialog,
    EventInfoDialog,
    EventEditDialog,
    EventCommentDialog,
  },
  methods: {
    openDetail(day) {
      this.$refs.detailDialog.open(day.year, day.month, day);
    },
    openInfo(eventId) {
      this.$refs.infoDialog.open(eventId);
    },
    openComment(eventId) {
      this.$refs.commentDialog.open(eventId);
    },
    openEdit(data) {
      this.$refs.editDialog.open(data);
    },
  },
};
