define (require,exports,module) ->
  do_when_result_search = _.wrap_submit (ev)->
    location.href = "result_record#show/#{encodeURIComponent($('#result-search-text').val())}"
  init: ->
    $("#result-search-form").on("submit",do_when_result_search)
    $("#result-search-text").on("change",->$("#result-search-form").submit())
    $("#result-search-text").select2(
      width: 'resolve'
      placeholder: '選手名'
      minimumInputLength: 1
      ajax:
        url: "api/result_misc/search_name"
        type: "POST"
        data: (term,page)->
          q: term
        results: (data,page) ->
          {results:({text:x} for x in data.results)}
      id: (x)->x.text
     )
