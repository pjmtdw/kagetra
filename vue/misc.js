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

    const $notify = $('<div role="alert"></div>').addClass(`notify alert alert-${type} alert-dismissible fade show w-25 m-1`)
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
