export default (routeName) => {
  // for navbar
  $(`nav #${routeName}`).addClass('active');

  // notify error message
  axios.interceptors.response.use(null, (error) => {
    $.notify('danger', `エラー: ${error.response.data.error_message}`);
    return Promise.reject(error);
  });

  // 通知機能追加
  // @param type 通知のスタイル(bootstrapのalert準拠. primaryなど)
  // @param message 通知の内容
  $.notify = (type, message) => {
    // クリア
    if (type === 'success') {
      $('.notify.alert-danger, .notify.alert-warning').remove();
    }
    if (type === 'clear') {
      $('.notify').remove();
      return;
    }
    // 重ならないようにずらす関数
    const alignNotify = () => {
      $('.notify').css('top', (i) => {
        let height = 0;
        $(`.notify:lt(${i})`).each((j, e) => {
          height += $(e).outerHeight(true);
        });
        return height;
      });
    };

    const $notify = $('<div role="alert"></div>')
      .addClass(`notify alert alert-${type} alert-dismissible fade show w-25 m-1`)
      .css({
        position: 'fixed',
        'z-index': 1200,
        right: '10px',
        'box-shadow': '5px 5px 10px 0 rgba(0, 0, 0, 0.2)',
        'min-width': '200px',
      })
      .html(message)
      .append($('<button class="close p-0 type="button" data-dismiss="alert" aria-label="Close"></button>')
        .css({ top: 0, right: 0 })
        .html('<span aria-hidden="true">&times;</span>'))
      .prependTo('#app');

    alignNotify();
    $notify.on('closed.bs.alert', alignNotify);

    // 10秒後に消える
    setTimeout(() => { $notify.remove(); }, 10 * 1000);
  };

  // 確認ダイアログ
  // @param message 確認メッセージ
  // @param title タイトル
  // @return Promise okならresolve
  $.confirm = (message, title = '確認') => {
    const $confirm = $(`
    <div class="modal fade" tabindex="-1" role="dialog">
      <div class="modal-dialog modal-dialog-centered modal-sm" role="document">
        <div class="modal-content bg-light" style="box-shadow: 5px 5px 10px 5px rgba(0, 0, 0, 0.2);">
          <div class="modal-header">
            <h5 class="modal-title">${title}</h5>
          </div>
          <div class="modal-body">
            <p>${message}</p>
          </div>
          <div class="modal-footer">
            <button type="button" class="btn btn-outline-secondary" data-dismiss="modal">キャンセル</button>
            <button type="button" class="btn btn-danger btn-ok" data-dismiss="modal">OK</button>
          </div>
        </div>
      </div>
    </div>`).css({
      'z-index': 1100,
    }).prependTo('#app');
    $confirm.modal();

    const def = new $.Deferred();
    const $ok = $('button.btn-ok', $confirm);
    const $cancel = $('button:not(.btn-ok)', $confirm);
    $ok.click((e) => {
      $(e.target).data('clicked', true);
    });
    $confirm.keydown((e) => {
      if (e.which === 13 || e.keyCode === 13) {
        // Enter
        $ok.click();
      } else if (_.includes([8, 46, 243], e.which) || _.includes([8, 46, 243], e.keyCode)) {
        // BS, Del, ESC
        $cancel.click();
      }
    });
    // 閉じた後にresolve or reject
    $confirm.on('hidden.bs.modal', () => {
      if ($('button.btn-ok', $confirm).data('clicked')) {
        def.resolve();
      } else {
        def.reject();
      }
      $confirm.remove();
    });
    return def.promise();
  };

  // 入力ダイアログ
  // @param title タイトル
  // @return Promise okならresolve, 引数はinputされた内容
  $.inputDialog = (title) => {
    const $dialog = $(`
    <div class="modal fade" tabindex="-1" role="dialog">
      <div class="modal-dialog modal-dialog-centered modal-sm" role="document">
        <div class="modal-content bg-light" style="box-shadow: 5px 5px 10px 5px rgba(0, 0, 0, 0.2);">
          <div class="modal-header">
            <h5 class="modal-title">${title}</h5>
          </div>
          <div class="modal-body">
            <form>
              <input type="text" class="form-control" required>
            </form>
          </div>
          <div class="modal-footer">
            <button type="button" class="btn btn-outline-secondary" data-dismiss="modal">キャンセル</button>
            <button type="button" class="btn btn-success btn-ok" data-dismiss="modal">OK</button>
          </div>
        </div>
      </div>
    </div>`).css({
      'z-index': 1100,
    }).prependTo('#app');
    $dialog.modal();

    const def = new $.Deferred();
    const $ok = $('button.btn-ok', $dialog);
    const $cancel = $('button:not(.btn-ok)', $dialog);
    $ok.click((e) => {
      $(e.target).data('clicked', true);
    });
    $dialog.keydown((e) => {
      if (e.which === 13 || e.keyCode === 13) {
        // Enter
        $ok.click();
      } else if (e.which === 243 || e.keyCode === 243) {
        // ESC
        $cancel.click();
      }
    });
    const $form = $('form', $dialog);
    $form.submit(e => e.preventDefault());
    $dialog.on('shown.bs.modal', () => {
      $('input', $dialog).focus();
    });
    $dialog.on('hide.bs.modal', (e) => {
      if ($ok.data('clicked') && !$form.check()) {
        $.notify('warning', '入力してください.');
        $ok.data('clicked', false);
        e.preventDefault();
      }
    });
    $dialog.on('hidden.bs.modal', () => {
      if ($ok.data('clicked')) {
        def.resolve($('input', $dialog).val());
      } else {
        def.reject();
      }
      $dialog.remove();
    });
    return def.promise();
  };

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
