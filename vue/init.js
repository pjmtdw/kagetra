import Vue from 'vue';

import TopBar from './components/TopBar.vue';
import NewCommentForm from './components/subcomponents/NewCommentForm.vue';
import CommentList from './components/subcomponents/CommentList.vue';
import Notifications from './components/subcomponents/Notifications.vue';
import Dialog from './components/subcomponents/Dialog.vue';

export default () => {
  // Mount
  new Vue(TopBar).$mount('#topbar');
  const n = new Vue(Notifications).$mount('#notifications');
  const d = new Vue(Dialog).$mount('#dialog');

  // Component
  Vue.component('NewCommentForm', NewCommentForm);
  Vue.component('CommentList', CommentList);

  // Mixin
  Vue.mixin({
    methods: {
      $_notify: n.notify,
      $_confirm: d.confirm,
      $_prompt: d.prompt,
      $_setBeforeUnload(isChanged) {
        window.addEventListener('beforeunload', (e) => {
          if (isChanged()) {
            e.returnValue = '';
            return '';
          }
          return undefined;
        });
      },
    },
  });

  // notify error message
  axios.interceptors.response.use(null, (error) => {
    $.vm.$_notify('danger', `エラー: ${error.response.data.error_message}`);
    return Promise.reject(error);
  });

  // 定数等
  $.util = {
    weekday_ja: '日月火水木金土日',
    result_str: { win: '○', lose: '●', now: '対戦中' },
    order_str: [null, '主将', '副将', '三将', '四将', '五将', '六将', '七将', '八将'],
  };
  // 日付(String)->Date. YYYY-MM-DD形式.
  $.util.parseDate = (str) => {
    const r = str.match(/^(\d{4})-(\d{2})-(\d{2})$/);
    if (r === null) return null;
    return new Date(Number(r[1]), Number(r[2]) - 1, Number(r[3]));
  };
  // Date->曜日(String)
  $.util.getWeekDay = (arg) => {
    let date = arg;
    if (typeof arg === 'string') {
      date = $.util.parseDate(arg);
    }
    if (!_.isDate(date)) {
      return null;
    }
    return $.util.weekday_ja[date.getDay()];
  };
  // 時間
  $.util.timeRange = (start, end) => {
    if (start && end) {
      return `${start} &sim; ${end}`;
    } else if (start) {
      return `${start} &sim;`;
    } else if (end) {
      return `&sim; ${end}`;
    }
    return '';
  };

  // jQuery拡張
  $.fn.extend({
    // formの値をobject化
    serializeObject() {
      const res = {};
      _.forEach(this.serializeArray(), (v) => {
        res[v.name] = v.value;
      });
      _.forEach(this.find('input[type="checkbox"]:not(:checked)'), (v) => {
        res[$(v).attr('name')] = false;
      });
      return res;
    },
    // formのバリデーション(無効な値があるとfalse)
    check() {
      this.removeClass('was-validated');
      if (this[0].checkValidity === undefined) {
        const check = (selector, cond) => {
          const arr = this.find(selector);
          for (let i = 0; i < arr.length; i++) {
            if (!cond(arr[i])) return false;
          }
          return true;
        };
        if (!check('[required]', e => e.value !== '')) return false;
        if (!check('[type="number"]', e => /^-?[0-9]*$/.test(e.value))) return false;
        if (!check('[pattern]', e => (new RegExp(e.getAttribute('pattern'))).test(e.value))) return false;
        return true;
      }
      if (!this[0].checkValidity()) {
        this.addClass('was-validated');
        return false;
      }
      return true;
    },
    // トグルbutton
    toggleBtnText(beforeText, afterText) {
      if (this.data('toggled')) {
        this.html(beforeText);
        this.data('toggled', false);
      } else {
        this.html(afterText);
        this.data('toggled', true);
      }
    },
  });
};
