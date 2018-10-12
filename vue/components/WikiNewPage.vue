<template>
  <main id="container" class="mx-auto">
    <div class="d-flex flex-row mt-5">
      <button class="btn btn-outline-info ml-auto" data-toggle="modal" data-target="#help_dialog">ヘルプ</button>
      <button class="btn btn-info ml-2" @click="showPreview">プレビュー</button>
      <button class="btn btn-success ml-2" @click="savePage">保存</button>
    </div>
    <div class="d-flex flex-row mt-3">
      <input v-model="title" type="text" class="form-control w-75" placeholder="タイトル">
      <label class="ml-auto mb-0">
        <input v-model="is_public" type="checkbox">
        外部公開
      </label>
    </div>
    <textarea v-model="body" class="form-control my-3" :rows="rows" placeholder="本文"/>
    <div id="help_dialog" class="modal fade">
      <div class="modal-dialog modal-lg">
        <div class="modal-content">
          <div class="modal-header">
            <h5 class="modal-title">Wikiの編集</h5>
            <button type="button" class="close" data-dismiss="modal" aria-label="Close">
              <span aria-hidden="true">&times;</span>
            </button>
          </div>
          <div class="modal-body">
            このWikiは
            <a href="http://ja.wikipedia.org/wiki/Markdown" target="_blank">Markdown記法</a>
            で書くことができます．記法についての説明は前述のリンクに委ねるとして，ここではこのWiki独自の仕様について説明します．
            ちなみに強制的に改行するには行末に空白2つ入れて下さい．
            <hr>
            このWikiでは任意のHTMLタグが使えます．また&lt;style&gt;を使うときは
            <code>.wiki-page</code>
            がページ内を示すセレクタです．
            <hr>
            Wiki内リンクは [[ ]] で囲みます．末尾に/log,/attached,/commentを付けるとそれぞれ履歴，添付，コメントへのリンクになります．
            <div class="panel">
              <code>
                <div>[[ リンク先タイトル ]]</div>
                <div>[[ リンク先タイトル | 表示される文字列 ]]</div>
                <div>[[ リンク先タイトル/attached ]]</div>
              </code>
            </div>
            <hr>
            テーブルを記述するには下記のようにします．ハイフンは3つ以上必要です．
            <div class="panel">
              <code>
                <div>| Item&nbsp;&nbsp; | Price |&nbsp;</div>
                <div>| ------ | ----- |&nbsp;</div>
                <div>| Apple&nbsp; | &nbsp;&nbsp;300 |&nbsp;</div>
                <div>| Banana | &nbsp;&nbsp;400 |&nbsp;</div>
              </code>
            </div>
            <hr>
            <div>「外部公開」にチェックを入れるとそのページを公開できます．ただしコメント，添付ファイル，履歴は公開されません．</div>
            <div>公開ページの一部を非公開にするには /* */ で囲みます．</div>
            <div class="panel">
              <code><div>この部分は公開 /* この部分は非公開 */</div></code>
            </div>
          </div>
        </div>
      </div>
    </div>
    <div ref="previewDialog" class="modal fade">
      <div class="modal-dialog modal-lg">
        <div class="modal-content">
          <div class="modal-header">
            <h5 class="modal-title">プレビュー</h5>
            <button type="button" class="close" data-dismiss="modal" aria-label="Close">
              <span aria-hidden="true">&times;</span>
            </button>
          </div>
          <div class="modal-body p-2">
            <div class="wiki-page" v-html="previewHtml"/>
          </div>
        </div>
      </div>
    </div>
  </main>
</template>
<script>
export default {
  data() {
    return {
      title: null,
      body: null,
      is_public: false,
      previewHtml: null,
    };
  },
  computed: {
    rows() {
      if (_.isNil(this.body)) return 4;
      return _.max([this.body.split('\n').length, 4]);
    },
  },
  methods: {
    showPreview() {
      if (_.isEmpty(this.body)) {
        this.$_notify('warning', '本文が空です');
        return;
      }
      axios.post('/wiki/preview', { body: this.body }).then((res) => {
        this.previewHtml = res.data.html;
        $(this.$refs.previewDialog).modal('show');
      });
    },
    savePage() {
      if (_.isEmpty(this.title)) {
        this.$_notify('warning', 'タイトルが空です');
        return;
      }
      if (_.isEmpty(this.body)) {
        this.$_notify('warning', '本文が空です');
        return;
      }
      const data = {
        title: this.title,
        public: this.is_public,
        body: this.body,
      };
      axios.post('/wiki/item', data).then((res) => {
        this.$router.push(`/${res.data.id}`);
      }).catch(this.$_makeOnFail('保存に失敗しました'));
    },
  },
};
</script>
<style lang="scss" scoped>
#container {
  width: 100%;
  max-width: 750px;
}
</style>
<style lang="scss">
@import '../sass/wiki.scss';
</style>
