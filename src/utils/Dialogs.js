import Vue from 'vue';
import { Message, MessageBox } from '@/components';
import { isObject } from 'lodash';

const variants = ['primary', 'secondry', 'success', 'danger', 'warning', 'info', 'light', 'dark'];

function makeMessage(variant) {
  return (a, b, c, d) => {
    let options;
    /**
     * $message(options)
     * $message(message, options?)
     * $message(variant, message, options?)
     * $message(title, message, options?)
     * $message(variant, title, message, options?)
     *
     * $message.info(options)
     * $message.info(message, options?)
     * $message.info(title, message, options?)
     */
    if (isObject(a)) {
      options = a;
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
      if (variant === undefined && variants.includes(a)) {
        options = {
          variant: a,
          message: b,
        };
      } else {
        options = {
          title: a,
          message: b,
        };
      }
    } else if (isObject(c)) {
      if (variant === undefined && variants.includes(a)) {
        options = {
          ...c,
          variant: a,
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
        variant: a,
        title: b,
        message: c,
      };
    } else {
      options = {
        ...d,
        variant: a,
        title: b,
        message: c,
      };
    }
    if (variant) options.variant = variant;
    new Vue(Message).open(options);
  };
}

function initMessage() {
  Vue.prototype.$message = makeMessage();
  Vue.prototype.$message.info = makeMessage('info');
  Vue.prototype.$message.success = makeMessage('success');
  Vue.prototype.$message.warn = makeMessage('warning');
  Vue.prototype.$message.error = makeMessage('danger');
}

function makeMessageBox(type) {
  return (a, b, c) => {
    let options;
    if (isObject(a)) {
      options = a;
    } else if (b === undefined) {
      options = {
        message: a,
      };
    } else if (isObject(b)) {
      if (type === 'confirm') {
        options = {
          ...b,
          message: a,
        };
      } else {
        options = {
          ...b,
          title: a,
        };
      }
    } else if (c === undefined) {
      options = {
        title: a,
        message: b,
      };
    } else if (isObject(c)) {
      options = {
        ...c,
        title: a,
        message: b,
      };
    }
    options.type = type;
    return new Vue(MessageBox).open(options);
  };
}

function initDialogs() {
  /**
   * $confirm(options)
   * $confirm(message, options?)
   * $confirm(title, message, options?)
   *
   * $prompt(options)
   * $prompt(title, options?)
   * $prompt(title, message, options?)
   */
  Vue.prototype.$confirm = makeMessageBox('confirm');
  Vue.prototype.$prompt = makeMessageBox('prompt');
}

export default function () {
  initMessage();
  initDialogs();
}
