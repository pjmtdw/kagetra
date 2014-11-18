# -*- coding: utf-8 -*-
class MainApp < Sinatra::Base
  EVENTS_PER_PAGE = 6 # 大会結果に表示される前後の大会の数
  EVENT_HALF_PAGE = EVENTS_PER_PAGE/2
  EVENT_GROUP_PER_PAGE = 20 # 過去の結果に表示される一ページあたりの大会数
  DROPDOWN_EVENT_GROUP_MAX = 20 # 過去の結果のドロップダウンに表示される大会数
  namespace '/api/result' do
    get '/contest/:id' do
      (evt,recent_list) = recent_contests(params[:id])
      if evt.nil?
        # 一つも大会結果がないときに表示
        return {
          name: "(大会結果はありません)",
          recent_list: [],
          group: [],
          team_size: 1,
          contest_classes: [],
          contest_results: [],
          id: -1,
        }
      end
      gr = evt.event_group
      group = if gr then
                fdate = if evt.date.nil? then Date.today else evt.date + 365*5 end
                gr.events_dataset.where(done:true).where{date <= fdate}.order(Sequel.desc(:date)).limit(DROPDOWN_EVENT_GROUP_MAX)
                .map{|x| x.select_attr(:id,:name,:date)}
              else [] end

      contest_results = if evt.team_size == 1 then
                        contest_results_single(evt) else
                        contest_results_team(evt) end

      contest_classes = Hash[evt.result_classes.map{|c| [c.id,c.select_attr(:class_name,:num_person)]}]

      evt.select_attr(:id,:name,:team_size,:date,:event_group_id,:kind,:official).merge({
        album_groups: evt.album_groups.map(&:id),
        recent_list: recent_list,
        group: group,
        team_size: evt.team_size,
        contest_classes: contest_classes,
        contest_results: contest_results
      })
    end

    # 日時順に並べたときの前後の大会
    def recent_contests(id)
      base = Event.where(kind:Event.kind__contest, done:true).where{contest_user_count > 0}
      evt = if id == "latest"
              then base.order(Sequel.desc(:date),Sequel.desc(:id)).first
              else Event[id.to_i] end
      return [nil,[]] if evt.nil?

      (pre,post) = [[:<,:desc],[:>,:asc]].map{|p,q|
        c1 = Sequel.expr(date:evt.date) & Sequel.expr{Sequel.expr(:id).send(p,evt.id)}
        c2 = Sequel.expr{date.send(p,evt.date)}
        base.where(c1|c2).order(Sequel.send(q,:date),Sequel.send(q,:id)).limit(EVENTS_PER_PAGE).to_a
      }

      first_is_most_recent = (post.size <= EVENT_HALF_PAGE)

      all = if pre.size <= EVENT_HALF_PAGE then
        (pre + [evt] + post)[0..EVENTS_PER_PAGE].reverse
      elsif post.size <= EVENT_HALF_PAGE then
        (post.reverse + [evt] + pre)[0..EVENTS_PER_PAGE]
      else
        (pre[0...EVENT_HALF_PAGE].reverse + [evt] + post[0...EVENT_HALF_PAGE]).reverse
      end

      list = all.to_enum.with_index(0).map{|x,i|
        r = x.select_attr(:id,:name,:date)
        if first_is_most_recent and i == 0 then
          r[:most_recent] = true
        end
        r
      }
      [evt,list]
    end

    # 個人戦の結果
    def contest_results_single(evt)
      # 後で少しずつ取得するのは遅いのでまとめて取得
      cls = evt.result_classes_dataset.order(Sequel.asc(:index))
      ugattrs = [:result,:opponent_name,:opponent_belongs,:score_str,:comment,:round]
      user_games = cls.map{|x|x.single_games_dataset.order(Sequel.asc(:round)).all}.flatten.map{|gm|
        [gm.contest_user_id,gm.select_attr(*ugattrs)]
      }.each_with_object(Hash.new{[]}){|(uid,attrs),h|
        if h[uid].empty?.! and attrs[:round] > h[uid].last[:round] +1 then
          # 回戦に抜けがあった場合は休みを入れる
          h[uid] += [{result: :break}] * (attrs[:round]-h[uid].last[:round]-1)
        end
        h[uid] <<= attrs
      }

      prattrs = [:prize, :point, :point_local]
      prizes = Hash[cls.map(&:prizes).flatten.map{|p|
        [p.contest_user_id, p.select_attr(*prattrs)]
      }]

      cls.map{|klass|
        rounds = get_klass_rounds(klass)
        round_num = rounds.size
        {
          class_id: klass.id,
          rounds: rounds,
          user_results: result_sort(klass,user_games,round_num,prizes)
        }
      }
    end

    def get_klass_rounds(klass)
      round_num = ContestGame.where(contest_class_id:klass.id).max(:round) || 0
      (1..round_num).map{|x|
        rn = klass.round_name
        {
          name: if rn and rn[x.to_s] then rn[x.to_s] end
        }
      }
    end

    def get_team_rounds(team)
      ops = team.opponents_dataset.order(Sequel.asc(:round))
      ops.to_enum.with_index(1).map{|x,i|{
        name: x.round_name,
        kind: x.kind,
        op_team_name: x.name
      }}
    end


    # 勝ち数の多い順に並べる
    def result_sort(klass,user_games,round_num,prizes)
      games = ContestGame.where(contest_class_id:klass.id)
      temp_res = {}

      # 後で少しずつ取得するのは遅いのでまとめて取得
      users = ContestUser.where(contest_class_id:klass.id).to_hash(:id,:name)

      users.keys.each{|uid|
        score = ["Z"] * round_num
        score_opt = ["Z"] * round_num # 同じ勝ち数の場合の順番
        user_games[uid].each_with_index{|m,index|
          (score[index],score_opt[index]) =
            case m[:result]
              when :win then ["A","A"]
              when :lose then ["C","C"]
              else ["A","B"]
            end
            temp_res[uid] = {
              score: score,
              score_opt: score_opt
            }
        }
      }
      # 自分が負けた以降の順番は負けた相手の成績順になる
      games.where(result: ContestGame.result__lose).order(Sequel.desc(:round)).each{|m|
        x = temp_res.find{|uid,v|users[uid] == m.opponent_name}
        if x then
          temp_res[m.contest_user_id][:score][m.round..-1] = x[1][:score][m.round..-1]
        end
      }
      res = temp_res.map{|uid,v|
        {user_id:uid}.merge(v)
      }.sort_by{|x|
        x[:score]+x[:score_opt]
      }.map{|x|
        uid = x[:user_id]
        r = {
          user_name: users[uid],
          game_results: user_games[uid],
          cuid: uid
        }
        if prizes.has_key?(uid) then
          r[:prize] = prizes[uid]
        end
        r
      }
      # 試合に出ていない選手を追加する
      res + users.to_a.map{|uid,uname|
        next if res.any?{|x|x[:cuid] == uid}
        {
          user_name: uname,
          cuid: uid,
          game_results: []
        }
      }.compact
    end

    # 団体戦の結果
    def contest_results_team(evt)
      teams = evt.result_classes_dataset.order(Sequel.asc(:index)).map(&:teams).flatten
      
      teams.map{|team|
        op_rounds = team.opponents_dataset.to_hash(:id,:round)
        max_round = op_rounds.size
        members = team.members_dataset.order(Sequel.asc(:order_num)).map(&:contest_user)
        prizes = Hash[ContestPrize.where(contest_user:members).map{|x|[x.contest_user_id,x]}]
        game_fields = [:opponent_name,:result,:score_str,:comment,:opponent_order,:opponent_belongs]
        games = ContestGame.where(contest_team_opponent_id:op_rounds.keys).all.group_by{|game| game.contest_user_id}
        user_results = members.map{|user|
          results = games[user.id] || []
          res = Hash[results.map{|game|
            [op_rounds[game.contest_team_opponent_id],game]
          }]
          game_results = (1..max_round).map{|round|
            game = res[round]
            if game then
              game.select_attr(*game_fields)
            else
              {result: "break"}
            end
          }
          r = {
            user_name: user.name,
            cuid: user.id,
            game_results: game_results
          }
          if prizes.has_key?(user.id) then
            r[:prize] = prizes[user.id].select_attr(:prize,:point_local)
          end
          r
        }
        hl = {team_name: team.name}
        if team.prize then
          hl[:team_prize] = team.prize
        end
        {
          class_id: team.contest_class_id,
          team_id: team.id,
          header_left: hl,
          rounds: get_team_rounds(team),
          user_results: user_results
        }
      }
    end

    def result_summary(ev)
      cache = ContestResultCache.first(event_id:ev.id)
      r = ev.select_attr(:id,:name,:date,:official)
      r.merge({
        user_count: ev.contest_user_count,
        win: if cache then cache.win else 0 end,
        lose: if cache then cache.lose else 0 end,
        prizes: if cache then cache.prizes else [] end
      })
    end
    get '/group/:id' do
      page = if params[:page].to_s.empty?.! then params[:page].to_i else 1 end
      group = EventGroup[params[:id].to_i]
      r = group.select_attr(:name,:description)
      chunks = group.events_dataset.where(done:true).order(Sequel.desc(:date)).paginate(page,EVENT_GROUP_PER_PAGE)
      list = chunks.map{|ev|
        result_summary(ev)
      }
      r.merge({list:list,cur_page:page,pages:chunks.page_count})
    end
    get '/players/:id' do
      ev = Event[params[:id].to_i]
      cc = ev.result_classes.all(order:[:index.asc])
      classes = cc.map{|x|[x.id,x.class_name]}
      users = Hash[ev.result_users.map{|x|[x.id,x.name]}]
      # 個人戦の場合は自由に移動できる
      not_movable = Hash[ev.result_users.map{|x|[x.id,ev.team_size > 1 && x.games.empty?.!]}]
      base = {users:users,classes:classes,not_movable:not_movable}
      if ev.team_size == 1 then
        user_classes = Hash[cc.map{|x|[x.id,x.users.map{|y|y.id}]}]
        base.merge({user_classes:user_classes})
      else
        tt = cc.teams
        teams = Hash[tt.map{|x|[x.id,x.name]}]
        team_classes = Hash[cc.map{|x|[x.id,x.teams.map{|y|y.id}]}]
        user_teams = Hash[tt.map{|x|[x.id,x.members.all(order:[:order_num.asc]).map{|y|y.contest_user_id}]}]
        # どのチームにも所属していない選手
        uu = user_teams.map{|x,y|y}.flatten
        neutral = Hash[cc.map{|x|[x.id,x.users.map{|y|y.id}-uu]}]
        base.merge({teams:teams,team_classes:team_classes,user_teams:user_teams,neutral:neutral})
      end
    end
    def update_result_users(ev,json)
      new_ids = {}
      json["users"].each{|k,v|
        kid = nil
        json["user_classes"].each{|p,q|
          kid = p if q.map{|x|x.to_s}.include?(k.to_s)
        }
        raise Exception.new("class id #{k.inspect} not found in #{json['user_classes'].inspect}") if kid.nil?
        klass = ContestClass[kid]
        raise Exception.new("class id #{kid} not found") if klass.nil?
        if k.to_s.start_with?("new_")
          us = User.first(name:v)
          user_id = if us then us.id end
          u = ContestUser.create(name:v,event_id:ev.id,contest_class_id:klass.id,user_id:user_id)
          new_ids[k] = u.id
        else
          u = ContestUser[k]
          u.update(contest_class:klass)
          if ev.team_size == 1 then
            u.games.update(contest_class_id:klass.id)
          end
          if u.prize then
            u.prize.update(contest_class_id:klass.id)
          end
        end
      }
      new_ids
    end
    put '/players/:id' do
      dm_response{
        DB.transaction{
          ev = Event[params[:id].to_i]
          @json["classes"].each_with_index{|(k,v),i|
            if k.to_s.start_with?("new_")
              kl = ContestClass.create(class_name:v,event_id:ev.id,index:i)
              ["user_classes","team_classes"].each{|key|
                if @json.has_key?(key) then
                  @json[key] = Hash[@json[key].map{|p,q|
                    [if p == k then kl.id else p end,q]
                  }]
                end
              }
            else
              ContestClass[k].update(index:i)
            end
          }
          if ev.team_size > 1 then
            @json["user_classes"] = Hash[@json["team_classes"].map{|k,v|
              [k,v.map{|x|@json['user_teams'][x.to_s]}.flatten+(@json["neutral"][k]||[])]
            }]
            new_ids = update_result_users(ev,@json)
            @json["teams"].each{|tid,tname|
              kid = nil
              @json["team_classes"].each{|p,q|
                kid = p if q.map{|x|x.to_s}.include?(tid.to_s)
              }
              klass = ContestClass[kid]
              members = @json["user_teams"][tid]

              team =  if tid.to_s.start_with?("new_")
                        ContestTeam.create(name:tname,contest_class_id:klass.id)
                      else
                        t = ContestTeam[tid]
                        t.update(contest_class_id:klass.id)
                        t
                      end
              team.members.destroy
              members.to_enum.with_index(1){|uid,i|
                if uid.to_s.start_with?("new_")
                  uid = new_ids[uid]
                end
                team.members << ContestTeamMember.new(contest_user_id:uid,contest_team_id:team.id,order_num:i)
              }
              team.save
            }
            @json["deleted_teams"].each{|x|
              t = ContestTeam[x]
              t.members.destroy
              if not t.destroy then raise Exception.new("cannot destroy #{t.inspect}") end
            }
          else
            update_result_users(ev,@json)
          end
          @json["deleted_users"].each{|x|
            cu = ContestUser[x]
            if not cu.destroy then raise Exception.new("cannot destroy #{cu.inspect}") end
          }
          @json["deleted_classes"].each{|x|
            cc = ContestClass[x]
            if not cc.destroy then raise Exception.new("cannot destroy #{cc.inspect}") end
          }
        }
      }
    end
    post '/num_person' do
      dm_response{
        DB.transaction{
          Hash[@json["data"].map{|x|
            np = x["num_person"]
            np = if np.to_i == 0 then nil else np.to_i end
            c = ContestClass[x["class_id"]]
            c.update(num_person: np)
            [c.id,c.num_person]
          }]
        }
      }
    end
    post '/update_round' do
      fields = ["score_str","opponent_name","opponent_belongs","comment","result"]
      dm_response{
        DB.transaction{
          klass = ContestClass[@json["class_id"]]
          round = @json["round"].to_i
          if not @json.has_key?("team_id")
            # 個人戦
            if @json["round_name"].to_s.empty?.! then
              klass.round_name[round.to_s] = @json["round_name"]
            else
              klass.round_name.delete(round.to_s)
            end
            klass.save
            condbase = {
                     contest_class_id: klass.id,
                     round: round
                   }
            gameclass = ContestSingleGame
          else
            # 団体戦
            fields << "opponent_order"
            team = ContestTeam[@json["team_id"]]
            rname = @json["round_name"]
            rkind = @json["round_kind"].to_sym
            opname = @json["op_team_name"]
            if opname == "delete" then
              team.opponents.first(round:round).destroy()
              return
            else
              op_team = ContestTeamOpponent.update_or_create(
                {contest_team_id:team.id,round:round},
                {name: opname,round_name: rname ,kind: rkind})
              condbase = {
                       contest_team_opponent_id: op_team.id,
                     }
              gameclass = ContestTeamGame
            end
          end
          @json["results"].each{|x|
            cond = condbase.merge({contest_user_id: x["cuid"]})
            if x["result"].to_s.empty? then
              gameclass.first(cond).tap{|y|if y then y.destroy() end}
            else
              gameclass.update_or_create(
                cond,
                x.select_attr(*fields)
              )
            end
          }

          rounds = if @json.has_key?("team_id")
                     get_team_rounds(team)
                    else
                     get_klass_rounds(klass)
                    end
          {
            results: Hash[gameclass.where(condbase).map{|x|[x.contest_user_id,x.select_attr(*fields)]}],
            rounds: rounds
          }
        }
      }
    end
    post '/update_prize' do
      dm_response{
        klass = ContestClass[@json["class_id"]]
        DB.transaction{
          @json["prizes"].each{|p|
            cond = {contest_class_id:klass.id,contest_user_id:p["cuid"]}
            if p["prize"].to_s.empty? then
              p = ContestPrize.first(cond)
              if p.nil?.! then
                p.destroy
              end
            else
              ContestPrize.update_or_create(
                cond,
                p.select_attr("point","point_local","prize")
              )
            end
          }
        }
        prizes = Hash[klass.prizes.map{|x|
          [x.contest_user_id,x.select_attr("prize","point","point_local")]
        }]
        res = {prizes: prizes}
        if @json.has_key?("team_id")
          team = ContestTeam[@json["team_id"]]
          team.update(prize:@json["team_prize"])
          res[:team_prize] = team.prize
        end
        res
      }
    end
  end
  get '/result' do
    haml :result
  end
  get '/result/excel/:id/:filename' do
    send_excel(Event[params[:id]])
  end
end
