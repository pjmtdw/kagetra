<template>
  <transition-group name="slide" tag="div" class="notifications mt-4 mr-2">
    <article v-for="n in notifications" :key="n.id" class="message" :class="n.classes">
      <div v-if="n.title" class="message-header">
        <p>{{ title }}</p>
        <button v-if="n.closable" class="delete" @click="close(n)"/>
      </div>
      <div v-else-if="n.closable" class="message-body close">
        <button class="delete" @click="close(n)"/>
      </div>
      <div class="message-body">
        {{ n.message }}
      </div>
    </article>
  </transition-group>
</template>
<script>
import { uniqueId } from 'lodash';

export default {
  data() {
    return {
      notifications: [],
    };
  },
  methods: {
    open(options) {
      const defaultOptions = {
        id: uniqueId(),
        duration: 5000,
        closable: true,
      };
      const newNotification = {
        ...defaultOptions,
        ...options,
      };
      if (newNotification.type) {
        newNotification.classes = `is-${newNotification.type}`;
      }
      this.notifications.push(newNotification);
      setTimeout(() => {
        this.close(newNotification);
      }, newNotification.duration);
    },
    close(notification) {
      const i = this.notifications.indexOf(notification);
      if (i !== -1) this.notifications.splice(i, 1);
    },
  },
};
</script>
<style lang="scss" scoped>
.notifications {
  position: absolute;
  top: 0;
  right: 0;
  z-index: 300;
  width: 300px;
  max-width: 70%;
}
.message {
  position: relative;
  box-shadow: 0 .5rem 1rem rgba(0, 0, 0, .15);
}
.message-body.close {
  display: flex;
  justify-content: flex-end;
  position: absolute;
  width: 100%;
  padding: .25rem .25rem 0 0;
}
button.delete {
  background-color: transparent;
  &::before, &::after {
    background-color: rgba(0, 0, 0, .4);
  }
}

.slide-enter, .slide-leave-to {
  transform: translateX(100%);
}
.slide-enter-active, .slide-leave-active {
  transition: transform .2s;
}
</style>
