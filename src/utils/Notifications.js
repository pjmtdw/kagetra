import Vue from 'vue';
import { Toast } from 'buefy/dist/components/toast';
import { Notifications } from '@/components';
import { isObject } from 'lodash';

function initToast() {
  Vue.prototype.$toast = (type, message, options) => {
    const defaultOptions = {
      type: 'is-info',
      position: 'is-bottom',
      duration: 5000,
    };
    if (isObject(type)) {
      Toast.open({
        ...defaultOptions,
        ...type,
      });
    }
    if (['white', 'black', 'light', 'dark', 'primary', 'info', 'success', 'warning', 'danger'].includes(type)) {
      Toast.open({
        ...defaultOptions,
        ...options,
        type: `is-${type}`,
        message,
      });
    } else if (isObject(message)) {
      Toast.open({
        ...defaultOptions,
        ...message,
        message: type,
      });
    } else {
      Toast.open({
        ...defaultOptions,
        message: type,
      });
    }
  };
}

const types = ['dark', 'primary', 'link', 'info', 'success', 'warning', 'danger'];

function makeNotify(notifications, type) {
  return (a, b, c, d) => {
    let options;
    /**
     * $notify(options)
     * $notify(message, options?)
     * $notify(type, message, options?)
     * $notify(title, message, options?)
     * $notify(type, title, message, options?)
     *
     * $notify.info(options)
     * $notify.info(message, options?)
     * $notify.info(title, message, options?)
     */
    if (isObject(a)) {
      options = {
        ...a,
      };
    } else if (b === undefined) {
      options = {
        message: a,
      };
    } else if (isObject(b)) {
      options = {
        ...b,
        message: a,
      };
    } else if (c === undefined) {
      if (type === undefined && types.includes(a)) {
        options = {
          type: a,
          message: b,
        };
      } else {
        options = {
          title: a,
          message: b,
        };
      }
    } else if (isObject(c)) {
      if (type === undefined && types.includes(a)) {
        options = {
          ...c,
          type: a,
          message: b,
        };
      } else {
        options = {
          ...c,
          title: a,
          message: b,
        };
      }
    } else if (d === undefined) {
      options = {
        type: a,
        title: b,
        message: c,
      };
    } else {
      options = {
        ...d,
        type: a,
        title: b,
        message: c,
      };
    }
    if (type) options.type = type;
    notifications.open(options);
  };
}

function initNotifications() {
  const container = document.createElement('div');
  document.body.appendChild(container);
  const notifications = new Vue(Notifications);
  notifications.$mount(container);
  Vue.prototype.$notify = makeNotify(notifications);
  Vue.prototype.$notify.info = makeNotify(notifications, 'info');
  Vue.prototype.$notify.success = makeNotify(notifications, 'success');
  Vue.prototype.$notify.warn = makeNotify(notifications, 'warning');
  Vue.prototype.$notify.error = makeNotify(notifications, 'danger');
}

export default function () {
  initToast();
  initNotifications();
}
