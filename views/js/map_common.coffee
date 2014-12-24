define ->
  {
    map_bookmark_search: ->
      select2_opts = {
        ajax:
          url: 'api/map/bookmark/complement'
          type: "POST"
          data: (term,page)->
            q: term
          results: (data,page) -> data
        id: (x)->x.id
      }
      _.cb_select2("地図ブックマーク検索", {}, select2_opts, {})
  }
