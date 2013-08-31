define (require,exports,module) ->
  # Requirng schedule_item in multiple scripts cause minified file larger
  # since both scripts contains whole content of schedule_item.js.
  # TODO: do not require schedule_item here and load it dynamically.
  $ed = require("event_detail")
  $co = require("comment")
  $rc = require("result_common")

  _.mixin
    make_order_num_select: (cur)->
      res = ["<option value=''>--</option>"]
      for num in [1..8]
        ja = _.order_to_ja(num)
        s = if cur && cur.opponent_order == num then "selected" else ""
        res.push("<option value='#{num}' #{s}>#{ja}</option>")
      "<select name='opponent_order'>#{res.join('')}</select>"


    make_point_select: (name,key,d)->
      pts = JSON.parse(g_points_str)[key]
      found = false
      res = []
      for p in [0].concat(pts)
        s = ""
        if p == d
          s = "selected"
          found = true
        res.push("<option value='#{p}' #{s}>#{p}</option>")
      if not found
        res.push("<option value='#{d}' selected>#{d}</option>")
      "<select name='#{name}'>#{res.join('')}</select>"

    make_result_select: (d)->
      res = []
      for [k,v] in [["","--"],["win","勝ち"],["lose","負け"],["default_win","不戦"],["now","途中"]]
        s = if k == d then "selected" else ""
        res.push("<option value='#{k}' #{s}>#{v}</option>")
      "<select name='result'>#{res.join('')}</select>"

    order_to_ja: (x)->
      switch x
        when 1 then "主将"
        when 2 then "副将"
        else "#{x}将"
    show_opponent_belongs: (team_size,s) ->
      return "" unless s
      r = []
      r.push s.opponent_belongs if s.opponent_belongs
      if team_size > 1
        r.push(_.order_to_ja(s.opponent_order)) if s.opponent_order?
      "(#{r.join(" / ")})" if r.length > 0
    show_header_left: (s) ->
      if not s?
        "名前"
      else
        a = $("<div>",text:_.escape(s.team_name))
        b = $("<div>",class:"team-prize",text:_.escape(s.team_prize))
        a[0].outerHTML + b[0].outerHTML


  ContestResultRouter = Backbone.Router.extend
    routes:
      "contest/:id": "contest"
      "": "contest"
    contest: (id)->
      if window.contest_result_edit_view?
        window.contest_result_edit_view.remove()
        delete window.contest_result_edit_view
      window.result_view.refresh(id)

  ContestChunkModel = Backbone.Model.extend {}

  ContestChunkView = Backbone.View.extend
    template: _.template_braces($('#templ-contest-chunk').html())
    initialize: ->
      @render()
    render: ->
      @$el.html(@template(data:_.extend(@model.toJSON(),chunk_index:@options.chunk_index,team_size:window.result_view.collection.team_size)))

  ContestEditRoundBase = Backbone.View.extend
    template: _.template_braces($('#templ-edit-round').html())
    events:
      "click .apply-edit" : "apply_edit"
    apply_edit: ->
      results = $.makeArray(@$el.find("form.changed").map(->
        obj = $(@).serializeObj()
        _.extend(obj,{cuid:$(@).data('cuid')})
      ))
      cindex = @options.chunk_index
      result = @collection.at(cindex)
      data = {
        results: results
        class_id: result.get('class_id')
        round: @options.round
        round_name: @$el.find(".round-name").val() || null
      }
      that = this
      $.ajax("api/result/update_round",{
        data: JSON.stringify(_.extend(data,@additional_send?(result)))
        contentType: "application/json"
        type: "POST"
      }).done((data)->
        if data._error_?
          alert(data._error_)
        else
          $("#container-result-edit").foundation("reveal","close")
          for r in result.get('user_results')
            if data.results[r.cuid]
              # 回戦に抜けがある場合は休みを入れる
              if r.game_results.length < that.options.round - 1
                for i in [1..(that.options.round - r.game_results.length - 1)]
                  r.game_results.push({result:"break"})
              r.game_results[that.options.round-1] = data.results[r.cuid]
            else
              delete r.game_results[that.options.round-1]
          result.set("rounds",data.rounds)
          that.do_after_apply?(result,data)
          window.result_view.refresh_chunk(cindex)
      )
    initialize: ->
      @render()
    render: ->
      round = @options.round
      cindex = @options.chunk_index
      result = @collection.at(cindex)
      klass = @collection.contest_classes[result.get('class_id')]
      round_info = (result.get('rounds')[round-1] || {name:null})
      round_name = round_info.name
      has_prev_lose = false
      that = this
      games = result.get('user_results').map((x)->
        prev_win = if round == 1 or that.round_kind?
                     true
                   else
                     c1 = x.game_results[round-1]
                     c2 = ["win","default_win"].indexOf((x.game_results[round-2]||{result:"lose"}).result) >= 0
                     c1 || c2
        if not prev_win
          has_prev_lose = true
        _.extend(x.game_results[round-1]||{},_.pick(x,"cuid","user_name"),{prev_win:prev_win})
      )
      data = {
        round_name: round_name
        round_num: round
        klass: klass
        games: games
        has_prev_lose: has_prev_lose
      }
      @$el.html(@template(data:_.extend(data,@additional_render?(result,round_info))))
      @$el.appendTo(@options.target)
      _.ie9_placeholder(@options.target)
      func = (ev)-> $(ev.currentTarget).closest("form").addClass("changed")
      @$el.find("input[type='text']").one('change',func)
      @$el.find("select").one('change',func)

      # モバイル端末などで大会結果がbodyの幅をはみ出た箇所で回戦の編集をしようとすると
      # Foundation の reveal は body の中 (モバイル端末の画面外) に表示される
      # なのであらかじめ body の中まで scroll しておく
      # TODO: scroll するのではなく reveal をモバイル端末の画面内に表示されるようにする
      if window.scrollTo? and window.pageYOffset?
        window.scrollTo(0,window.pageYOffset)

  class ContestEditTeamRoundView extends ContestEditRoundBase
    events: _.extend(ContestEditRoundBase.prototype.events,
      "click #round-kind .choice" : "change_round_kind"
    )
    change_round_kind: (ev)->
      @round_kind = $(ev.currentTarget).data("kind")
      @render()
    additional_render: (result,round_info) ->
      hl = result.get('header_left')
      {
        team_name: hl.team_name
        op_team_name: round_info.op_team_name
        round_kind: @round_kind
        mode: "team"
      }
    additional_send: (result)->
      {
        op_team_name: @$el.find(".op-team-name").val() or null
        round_kind: @round_kind
        team_id: result.get("team_id")
      }
    initialize: ->
      round = @options.round
      cindex = @options.chunk_index
      result = @collection.at(cindex)
      @round_kind = (result.get('rounds')[round-1] || {kind:"team"}).kind
      super()



  class ContestEditSingleRoundView extends ContestEditRoundBase
    events: _.extend(ContestEditRoundBase.prototype.events,
      "click .show-loser" : "show_loser"
    )
    show_loser: ->
      @$el.find(".each-result.hide").show()
      @$el.find(".show-loser").remove()

  ContestEditNumPersonView = Backbone.View.extend
    template: _.template_braces($('#templ-edit-num-person').html())
    events:
      "click .apply-edit" : "apply_edit"
    apply_edit: ->
      cid2num = {}
      data = $.makeArray(@$el.find("[data-class-id]").map(->
        {
          class_id: $(@).data('class-id')
          num_person: $(@).val()
        }
      ))
      kls = @collection.contest_classes
      $.ajax("api/result/num_person",{
        data: JSON.stringify({data:data})
        contentType: "application/json"
        type: "POST"
      }).done((data)->
        for k,v of kls
          kls[k].num_person = data[k]
        window.result_view.render_edit_mode()
        $("#container-result-edit").foundation("reveal","close")
      )

    initialize: ->
      @render()
    render: ->
      col = @collection
      data = col.map((x)->
        kid = x.get('class_id')
        _.extend(col.contest_classes[kid],{class_id:kid})
      )
      @$el.html(@template(data:data))
      @$el.appendTo(@options.target)

  ContestEditViewBase = Backbone.View.extend
    el: '#contest-result-body'
    events:
      'click .round-name' : 'edit_round'
      'click th.leftmost' : 'edit_prize'
    initialize: ->
      @render()
    render: ->
      $("#edit-player").hide()
      @$el.find("a").removeAttr("href")
      @$el.find(".round-name.hide").show()
      @$el.find(".round-name").addClass("editable")
    show_help: (helps)->
      return if $("#edit-help").length > 0
      $("#edit-player").after($("<ul>",{id:"edit-help"}))
      for h in helps
        $("#edit-help").append($("<li>",{text:h}))
    reveal_view: (klass,options)->
      options ||= {}
      target = "#container-result-edit"
      v = new klass(_.extend(options,{target:target,collection:@collection}))
      _.reveal_view(target,v,true)
    get_chunk_data: (ev)->
      obj = $(ev.currentTarget)
      round = obj.data("round")
      chunk_index = obj.closest("[data-chunk-index]").data("chunk-index")
      {round:round,chunk_index:chunk_index}

  class ContestEditTeamView extends ContestEditViewBase
    render: ->
      super()
      @$el.find("th.leftmost").addClass("editable")
      @show_help([
        "〜回戦をクリックするとその回戦の結果を編集できます",
        "自チーム名をクリックするとチーム入賞，個人賞を編集できます"
      ])
    edit_round: (ev)->
      @reveal_view(ContestEditTeamRoundView,@get_chunk_data(ev))
    edit_prize: (ev)->
      @reveal_view(ContestEditTeamPrizeView,@get_chunk_data(ev))

  ContestEditPrizeBase = Backbone.View.extend
    template: _.template_braces($('#templ-edit-prize').html())
    events:
      "click .apply-edit" : "apply_edit"
    apply_edit: ->
      prizes = $.makeArray(@$el.find("form.changed").map(->
        obj = $(@).serializeObj()
        _.extend(obj,{cuid:$(@).data('cuid')})))
      cindex = @options.chunk_index
      result = @collection.at(cindex)
      data = {
        class_id: result.get('class_id')
        prizes: prizes
      }
      that = this
      $.ajax("api/result/update_prize",{
        data: JSON.stringify(_.extend(data,@additional_send?(result)))
        contentType: "application/json"
        type: "POST"
      }).done((data)->
        if data._error_?
          alert(data._error_)
        else
          $("#container-result-edit").foundation("reveal","close")
          for r in result.get('user_results')
            if data.prizes[r.cuid]
              r.prize = data.prizes[r.cuid]
            else
              delete r.prize
          that.do_after_apply?(result,data)
          window.result_view.refresh_chunk(cindex)

      )
    initialize: -> @render()
    render: ->
      cindex = @options.chunk_index
      result = @collection.at(cindex)
      klass = @collection.contest_classes[result.get('class_id')]
      list = (for r in result.get('user_results')
               _.pick(r,"cuid","prize","user_name"))
      data = {
        klass: klass
        list:list
      }
      @$el.html(@template(data:_.extend(data,@additional_render?(result))))
      @$el.appendTo(@options.target)
      func = (ev)-> $(ev.currentTarget).closest("form").addClass("changed")
      @$el.find("input[type='text']").one('change',func)
      @$el.find("select").one('change',func)

  class ContestEditSinglePrizeView extends ContestEditPrizeBase
    additional_render: (result)->
      {
        message: "※ &quot;優勝(昇級)&quot; のように昇級やダッシュなどは()で囲って下さい"
        point_local_key: "single_point_local"
      }


  class ContestEditTeamPrizeView extends ContestEditPrizeBase
    additional_render: (result)->
      hl = result.get('header_left')
      {
        message: "※ &quot;優勝(昇級)&quot; のように昇級や陥落などは()で囲って下さい"
        team_prize: hl.team_prize
        no_point: true
        point_local_key: "team_point_local"
        team_name: hl.team_name
      }
    additional_send: (result) ->
      {
        team_id: result.get("team_id")
        team_prize: @$el.find(".team-prize").val() || null
      }
    do_after_apply: (result,data)->
      result.get('header_left')["team_prize"] = data.team_prize


  #template: _.template_braces($('#templ-edit-team-prize').html())

  class ContestEditSingleView extends ContestEditViewBase
    events: _.extend(ContestEditViewBase.prototype.events,
      'click .num-person' : 'edit_num_person'
    )
    edit_round: (ev)->
      @reveal_view(ContestEditSingleRoundView,@get_chunk_data(ev))
    edit_prize: (ev)->
      @reveal_view(ContestEditSinglePrizeView,@get_chunk_data(ev))
    edit_num_person: -> @reveal_view(ContestEditNumPersonView)

    render: ->
      super()
      @$el.find("th.leftmost").html("<div>入賞編集</div>").addClass("editable")
      @$el.find(".num-person").show().addClass("editable")
      @show_help([
        "〜回戦をクリックするとその回戦の結果を編集できます",
        "級の参加人数をクリックするとそれを編集できます"
      ])

  ContestResultCollection = Backbone.Collection.extend
    url: -> 'api/result/contest/' + (@id or "latest")
    model: ContestChunkModel
    parse: (data)->
      for x in ["recent_list","name","date","id","kind","official"
        "contest_classes","group","team_size","event_group_id"]
        @[x] = data[x]
      data.contest_results
  ContestPlayerModel = Backbone.Model.extend
    urlRoot: 'api/result/players'
    defaults: ->
      deleted_classes: []
      deleted_users: []
      deleted_teams: []
  ContestPlayerView = Backbone.View.extend
    events:
      "click .apply-edit" : "apply_edit"
      "click .add-class" : "add_class"
      "click .delete-class" : "delete_class"
      "click .delete-player" : "delete_player"
      "click .add-player" : "add_player"
      "click .move-player" : "move_player"
    apply_edit: ->
      that = this
      @model.save().done(->
        window.result_view.collection.fetch()
        $("#container-result-edit").foundation("reveal","close")
      )
    get_checked: ->
      $.makeArray(@$el.find("form :checked").map(->$(@).data("id")))
    initialize: ->
      @newid = 1
      @model = new ContestPlayerModel(id:@options.id)
      @listenTo(@model,'sync',@render)
      @model.fetch()
    render: ->
      @$el.html(@template(data:@model.toJSON()))
      @$el.appendTo(@options.target)
      _.ie9_placeholder(@options.target)
    add_class: ->
      classes = (x for x in @$el.find(".class-to-add").val().split(/\s+/) when x)
      classes.reverse()
      target = @$el.find(".add-class-target select").val()
      position = @$el.find(".add-class-position").val()
      kls = @model.get('classes')
      index = if target then (i.toString() for [i,j] in kls).indexOf(target) else 0
      if position == "after"
        index += 1
      for c in classes
        nid = "new_#{@newid}"
        @newid += 1
        kls.splice(index,0,[nid,c])
        for s in ["user_classes","team_classes"]
          if @model.has(s)
            @model.get(s)[nid] = []
      @render()
    delete_class_common: (cs...)->
      cl = @$el.find(".class-to-delete select").val()
      return unless cl
      for c in cs
        kls = @model.get(c)
        if not _.isEmpty(kls[cl])
          alert("空でない級は削除できません")
          return
      for c in cs
        kls = @model.get(c)
        delete kls[cl]
      @model.get("deleted_classes").push(cl) if cl.toString().indexOf("new_") != 0
      nclass = ([k,v] for [k,v] in @model.get('classes') when k.toString() != cl.toString())
      @model.set('classes',nclass)
      @render()
    add_player_common: (belongs)->
      players = (x for x in @$el.find(".player-to-add").val().split(/\s+/) when x)
      cl = @$el.find(".player-to-add-belong select").val()
      return unless cl
      for p in players
        nid = "new_#{@newid}"
        @newid += 1
        @model.get(belongs)[cl].push(nid)
        @model.get('users')[nid] = p
      @render()
    move_player_common: (belongs)->
      checked = @get_checked()
      cl = @$el.find(".player-to-move-belong select").val()
      return unless cl
      ucs = @model.get(belongs)
      get_belong_from_id = (id)->
        for k,v of ucs
          return k if v.indexOf(id) >= 0
      # 移動不可でも同チーム内での順番変更は可能
      checked = (c for c in checked when ((not @model.get('not_movable')[c]) or get_belong_from_id(c) == cl))
      @remove_player_belong(checked)
      ucs[cl] = ucs[cl].concat(checked)
      @render()
    delete_player: ->
      checked = @get_checked()
      checked = (c for c in checked when not @model.get('not_movable')[c])
      users = @model.get('users')
      @remove_player_belong(checked)
      for c in checked
        @model.get("deleted_users").push(c) if c.toString().indexOf("new_") != 0
        delete users[c]
      @render()
    remove_player_belong_common: (checked, belongs...)->
      for b in belongs
        belong = @model.get(b)
        for k,v of belong
          belong[k] = _.difference(v,checked)

  class ContestSinglePlayerView extends ContestPlayerView
    template: _.template_braces($('#templ-single-player').html())
    remove_player_belong: (checked)->
      @remove_player_belong_common(checked,'user_classes')
    delete_class: ->
      @delete_class_common('user_classes')
    add_player: ->
      @add_player_common('user_classes')
    move_player: ->
      @move_player_common('user_classes')

  class ContestTeamPlayerView extends ContestPlayerView
    template: _.template_braces($('#templ-team-player').html())
    events:
      _.extend(ContestPlayerView.prototype.events,
        "click .delete-team" : "delete_team"
        "click .add-team" : "add_team"
      )
    delete_class: ->
      @delete_class_common('team_classes','neutral')
    add_player: ->
      @add_player_common('user_teams')
    move_player: ->
      @move_player_common('user_teams')
    remove_player_belong: (checked)->
      @remove_player_belong_common(checked,'user_teams','neutral')
    add_team: ->
      team = (x for x in @$el.find(".team-to-add").val().split(/\s+/) when x)
      cl = @$el.find(".team-to-add-class select").val()
      return unless cl
      for t in team
        nid = "new_#{@newid}"
        @newid += 1
        @model.get('team_classes')[cl].push(nid)
        @model.get('teams')[nid] = t
        @model.get('user_teams')[nid] = []
      @render()

    delete_team: ->
      tid = _.to_int_if_digit(@$el.find(".team-to-delete select").val())
      return unless tid
      team = @model.get('user_teams')
      if not _.isEmpty(team[tid])
        alert("空でないチームは削除できません")
        return
      delete team[tid]
      delete @model.get("teams")[tid]
      @model.get("deleted_teams").push(tid) if tid.toString().indexOf("new_") != 0
      team_classes = @model.get('team_classes')
      for k,v of team_classes
        team_classes[k] = _.without(v,tid)
      @render()

  # TODO: split this view to ContestInfoView which has name, date, group, list  and ContestResultView which only has result
  ContestResultView = Backbone.View.extend
    el: '#contest-result'
    template: _.template_braces($('#templ-contest-result').html())
    events:
      "click .contest-link": "contest_link"
      "click #show-event-group": "show_event_group"
      "click #contest-add": "contest_add"
      "click #toggle-edit-mode" : "toggle_edit_mode"
      "click #edit-player" : "edit_player"
    edit_player : ->
      target = "#container-result-edit"
      klass = if @collection.team_size == 1 then ContestSinglePlayerView else ContestTeamPlayerView
      v = new klass(target:target,id:@collection.id)
      _.reveal_view(target,v)

    toggle_edit_mode: ->
      if window.contest_result_edit_view?
        window.contest_result_edit_view.remove()
        delete window.contest_result_edit_view
        @collection.fetch()
      else
        @start_edit_mode()
    start_edit_mode: ->
      $("#toggle-edit-mode").toggleBtnText(false)
      $("#edit-class-info").hide()
      klass = if @collection.team_size == 1 then ContestEditSingleView else ContestEditTeamView
      window.contest_result_edit_view = new klass(collection:@collection)
    show_event_group: _.wrap_submit ->
      $ed.show_event_group(@collection.event_group_id)
      false
    contest_add: ->
      $ed.show_event_edit(
        new $ed.EventItemModel(kind:"contest",id:"contest",done:true),
        {do_when_done:(m)-> window.result_router.navigate("contest/#{m.get('id')}",trigger:true)}
      )
    contest_link: (ev) ->
      id = $(ev.currentTarget).data('id')
      window.result_router.navigate("contest/#{id}",trigger:true)
    initialize: ->
      _.bindAll(this,"render","refresh","contest_link","show_event_group")
      @collection = new ContestResultCollection()
      @listenTo(@collection,"sync",@render)
    render_edit_mode: ->
      window.contest_result_edit_view.remove()
      @render()
      @start_edit_mode()

    render: ->
      col = @collection
      @$el.html(@template(data:_.pick(@collection,"id","recent_list","group","name","date","kind","official")))
      cur_class = null
      @chunks = []
      that = this
      col.each (m,index)->
        if m.get("class_id") != cur_class
          cur_class = m.get("class_id")
          cinfo = col.contest_classes[cur_class]
          c = $("<div>",{class:"class-info"})
          c.append($("<span>",{class:"class-name label round",text:cinfo.class_name}))
          np = cinfo.num_person || 0
          cl = $("<span>",{class:"num-person label",text:np + "人"})
          c.append(cl)
          cl.hide() if np == 0

          $("#contest-result-body").append(c)
        v = new ContestChunkView(model:m,chunk_index:index)
        that.chunks.push(v)
        $("#contest-result-body").append(v.$el)

      @$el.foundation('section','reflow')
      $co.section_comment(
        "event",
        "#event-comment",
        col.id,
        $("#event-comment-count"))
      new ContestInfoView(id:col.id)
    refresh: (id) ->
      @collection.id = id
      @collection.fetch()
    refresh_chunk: (cindex) ->
      @chunks[cindex].render()
      window.contest_result_edit_view.render()

  ContestInfoView = Backbone.View.extend
    el: "#contest-info"
    initialize: ->
      @render()
    render: ->
      @model = new $ed.EventItemModel(id:@options.id)
      v = new $ed.EventDetailView(target:"#contest-info",model:@model,no_participant:true)
      @model.fetch(data:{detail:true,no_participant:true})
  init: ->
    window.result_router = new ContestResultRouter()
    window.result_view = new ContestResultView()
    $rc.init()
    Backbone.history.start()
