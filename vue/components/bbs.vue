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
        const THREADS_PER_PAGE = res.data.pop().tpp;
        const COUNT = res.data.pop().count;
        this.threads = res.data;
        const max = Math.floor((COUNT - 1) / THREADS_PER_PAGE) + 1;
        const p = Number(page);
        if (p < 6) {
          this.pages = max > 10 ? 10 : max;
        } else if (p > max - 5) {
          this.pages = [];
          for (let i = p - 5; i <= max; i++) {
            this.pages.push(i);
          }
        } else {
          this.pages = [];
          for (let i = p - 5; i <= p + 5; i++) {
            this.pages.push(i);
          }
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
