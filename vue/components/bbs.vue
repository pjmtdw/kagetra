<template>
  <div class='mx-auto' style='width:45em;'>
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
  created() {
    axios.get('/api/bbs/threads?page=1').then((res) => {
      this.threads = res.data;
    });
  },
  data() {
    return {
      threads: [],
    };
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
