import Vue from 'vue';

import TopBar from './components/TopBar.vue';
import NewCommentForm from './components/subcomponents/NewCommentForm.vue';
import TooltipIcon from './components/subcomponents/TooltipIcon.vue';
import Notifications from './components/subcomponents/Notifications.vue';
import Dialog from './components/subcomponents/Dialog.vue';

export default () => {
  // Mount
  new Vue(TopBar).$mount('#topbar');
  const n = new Vue(Notifications).$mount('#notifications');
  const d = new Vue(Dialog).$mount('#dialog');

  // Component
  Vue.component('NewCommentForm', NewCommentForm);
  Vue.component('TooltipIcon', TooltipIcon);

  // Mixin
  Vue.mixin({
    methods: {
      // template内で使えるようにするためのラッパー
      /* eslint-disable-next-line no-console */
      $_log: console.log,

      // ダイアログなど
      $_notify: n.notify,
      $_confirm: d.confirm,
      $_prompt: d.prompt,

      // util
      $_makeOnFail(message) {
        return () => this.$_notify('danger', message);
      },
      $_assert(v) {
        if (!v) throw Error('Assertion Error');
      },
      $_setBeforeUnload(isChanged) {
        window.addEventListener('beforeunload', (e) => {
          if (isChanged()) {
            e.returnValue = '';
            return '';
          }
          return undefined;
        });
      },
      $_timeRange(_start, _end, emphStart = false, emphEnd = false) {
        let start = _start;
        let end = _end;
        if (start && emphStart) start = `<strong><u>${start}</u></strong>`;
        if (end && emphEnd) end = `<strong><u>${end}</u></strong>`;
        if (start && end) {
          return `${start}&sim;${end}`;
        } else if (start) {
          return `${start}&sim;`;
        } else if (end) {
          return `&sim;${end}`;
        }
        return '';
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
    breakpoints: { sm: 576, md: 768, lg: 992, xl: 1200 },
    weekday_ja: '日月火水木金土日',
    result_str: { win: '○', lose: '●', now: '対戦中' },
    results_jp: { win: '勝ち', lose: '負け', now: '途中', default_win: '不戦' },
    order_str: [null, '主将', '副将', '三将', '四将', '五将', '六将', '七将', '八将'],
    /* eslint-disable no-restricted-properties */
    points: _.map(_.range(8), x => (x > 0 ? Math.pow(2, x - 1) : 0)),
    local_points: _.map(_.range(10), x => (x > 0 ? Math.pow(2, x - 1) : 0)),
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
