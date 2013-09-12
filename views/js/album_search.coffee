define (require,exports,module)->
  require("jquery_lazyload")
  AlbumSearchView = Backbone.View.extend
    template: _.template_braces($("#templ-album-search").html())
    template_result: _.template_braces($("#templ-album-search-result").html())
    events:
      "submit .search-form" : "do_submit"
      "click .page" : "goto_page"
    initialize: ->
      @render()
    render: ->
      @$el.html(@template())
      @$el.find(".search-form input[name='qs']").val(@options.init_qs)
      if @options.top_message?
        @$el.find(".top-message").text(@options.top_message)
      if @options.target? # Foundation の Reveal 上での表示
        @$el.appendTo(@options.target)
      else
        @$el.appendTo("#album-search")
    research: (page)->
      qs = @$el.find(".search-form input[name='qs']").val()
      if @options.do_when_research?
        @options.do_when_research(qs,page)
      else
        @search(qs,page)
    goto_page: (ev)->
      obj = $(ev.currentTarget)
      @research(obj.data("page"))
    do_submit: _.wrap_submit ->
      @research(1)
    search: (qs,page)->
      that = this
      $.post("api/album/search",{qs:qs,page:page}).done((data)->
        that.data = data
        that.$el.find(".search-result").html(that.template_result(data:data))
        if that.options.do_after_search?
          that.options.do_after_search()
        if that.options.do_when_click
          o = that.$el.find(".search-result .thumbnail a")
          o.removeAttr("href")
          o.click(that.options.do_when_click)
        $("img.lazy").lazyload({effect:"fadeIn"})
      )
  {
    AlbumSearchView: AlbumSearchView
  }
