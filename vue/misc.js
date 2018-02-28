export default (routeName) => {
  // for navbar
  $(`nav #${routeName}`).addClass('active');

  // 通知機能追加
  // @param type 通知のスタイル(bootstrapのalert準拠. primaryなど)
  // @param message 通知の内容
  $.notify = (type, message) => {
    // クリア
    if (type === 'clear') {
      $('.notify.alert-danger, .notify.alert-warning').remove();
      return;
    }
    if (type === 'clear-all') {
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
        'z-index': 200,
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

    const promise = new $.Deferred();
    $('button.btn-ok', $confirm).click(() => {
      promise.resolve();
    });
    $confirm.on('hidden.bs.modal', () => {
      if (promise.state() === 'pending') {
        promise.reject();
      }
      $confirm.remove();
    });
    return promise;
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
            <input type="text" class="form-control">
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

    const promise = new $.Deferred();
    $('button.btn-ok', $dialog).click(() => {
      promise.resolve($('input', $dialog).val());
    });
    $dialog.on('hidden.bs.modal', () => {
      if (promise.state() === 'pending') {
        promise.reject();
      }
      $dialog.remove();
    });
    return promise;
  };

  // formの値をobject化
  $.fn.extend({
    serializeObject() {
      const res = {};
      _.forEach(this.serializeArray(), (v) => {
        res[v.name] = v.value;
      });
      return res;
    },
  });

  axios.interceptors.response.use(null, (error) => {
    $.notify('danger', `エラー: ${error.response.data.error_message}`);
    return Promise.reject(error);
  });
};
