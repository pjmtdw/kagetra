<template>
  <div class='mx-auto' style='width:45em;'>
    <ul class='pagination'>
      <li class='page-item' v-for='page in 10'>
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
    };
  },
  methods: {
    fetch(page) {
      axios.get(`/api/bbs/threads?page=${page}`).then((res) => {
        this.threads = res.data;
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
