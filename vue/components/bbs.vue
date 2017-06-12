<template>
  <div class='mx-auto' style='width:45em;'>
    <ul class='pagination'>
      <li class='page-item' v-for='page in pages'>
        <router-link class='page-link' :to='page.toString()'>{{page}}</router-link>
      </li>
    </ul>
    <div class='card thread' v-for='thread in threads'>
      <div class='card-header'>
        {{thread.title}}
      </div>
      <ul class="list-group list-group-flush">
        <li class='list-group-item' v-for='item in thread.items'>
          <div>
            <span class='name'>{{item.user_name}}</span>＠<span class='date'>{{item.date}}</span>
          </div>
          {{item.body}}
        </li>
      </ul>
    </div>
  </div>
</template>
<script>
export default {
  props: ['page'],
  created() {
    this.fetch(this.page);
  },
  data() {
    return {
      threads: [],
      pages: [],
    };
  },
  methods: {
    fetch(page) {
      axios.get(`/api/bbs/threads?page=${page}`).then((res) => {
        const PAGINATE_LIMIT = 5;
        const THREADS_PER_PAGE = res.data.pop().tpp;
        const COUNT = res.data.pop().count;
        this.threads = res.data;

        const max = Math.floor((COUNT - 1) / THREADS_PER_PAGE) + 1;
        const p = Number(page);
        if (p <= PAGINATE_LIMIT) {
          this.pages = _.range(1, _.min([max, PAGINATE_LIMIT * 2]) + 1);
        } else if (p > max - PAGINATE_LIMIT) {
          this.pages = _.range(p - PAGINATE_LIMIT, max + 1);
        } else {
          this.pages = _.range(p - PAGINATE_LIMIT, p + PAGINATE_LIMIT + 1);
        }
      });
    },
  },
  watch: {
    page(val) {
      this.fetch(val);
    },
  },
};
</script>
<style scoped>
.thread {
  white-space: pre-line;
  margin-bottom: 1.5em;
}

.name {
  color: #040;
}

.date {
  color: brown;
}
</style>
