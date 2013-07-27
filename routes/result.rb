# -*- coding: utf-8 -*-
class MainApp < Sinatra::Base
  EVENTS_PER_PAGE = 6
  HALF_PAGE = EVENTS_PER_PAGE/2
  DROPDOWN_EVENT_GROUP_MAX = 20
  EVENT_GROUP_PER_PAGE = 20
  namespace '/api/result' do
    get '/contest/:id' do
      (evt,recent_list) = recent_contests(params[:id])

      gr = evt.event_group
      group = if gr then 
                fdate = if evt.date.nil? then Date.today else evt.date + 365*5 end
                gr.events(done:true, :date.lte => fdate, order:[:date.desc])[0...DROPDOWN_EVENT_GROUP_MAX]
                .map{|x| x.select_attr(:id,:name,:date)}
              else [] end
      
      contest_results = if evt.team_size == 1 then
                        contest_results_single(evt) else
                        contest_results_team(evt) end

      contest_classes = Hash[evt.result_classes.map{|c| [c.id,c.class_name]}]

      evt.select_attr(:id,:name,:team_size,:date,:event_group_id).merge({
        recent_list: recent_list,
        group: group,
        team_size: evt.team_size,
        contest_classes: contest_classes,
        contest_results: contest_results
      })
    end

    # 日時順に並べたときの前後の大会
    def recent_contests(id)
      cond0 = Event.all(kind: :contest, done:true)
      cond = (cond0 &
              (Event.all(:participant_count.gt => 0) | Event.all(:contest_user_count.gt => 0)) )
      evt = (cond0 & Event.all(
              if id == "latest" then
                {order: [:date.desc,:id.desc]}
              else
                {id: id.to_i}
              end
            )).first
      (pre,post) = [[:lt,:desc],[:gt,:asc]].map{|p,q|
        (cond & (Event.all(date:evt.date, :id.send(p) => evt.id) | Event.all(:date.send(p) => evt.date)))
        .all(order: [:date.send(q), :id.send(q)])[0...EVENTS_PER_PAGE]
      }
      # 実際にクエリ実行する(この行を入れないとうまく動かない)
      pre = pre.to_a
      post = post.to_a

      all = if pre.size <= HALF_PAGE then
        (pre + [evt] + post)[0..EVENTS_PER_PAGE].reverse
      elsif post.size <= HALF_PAGE then
        (post.reverse + [evt] + pre)[0..EVENTS_PER_PAGE]
      else
        (pre[0...HALF_PAGE].reverse + [evt] + post[0...HALF_PAGE]).reverse
      end

      list = all.map{|x| x.select_attr(:id,:name)}
      [evt,list]
    end

    # 個人戦の結果
    def contest_results_single(evt)
      # 後で少しずつ取得するのは遅いのでまとめて取得
      cls = evt.result_classes
      ugattrs = [:result,:opponent_name,:opponent_belongs,:score_str]
      user_games = cls.single_games.all(fields:[:contest_user_id,*ugattrs]).map{|gm|
        [gm.contest_user_id,gm.select_attr(*ugattrs)]
      }.each_with_object(Hash.new{[]}){|(uid,attrs),h|
        h[uid] <<= attrs
      }
      prattrs = [:prize, :point, :point_local]
      prizes = Hash[cls.prizes.all(fields:[:contest_user_id,*prattrs]).map{|p|
        [p.contest_user_id, p.select_attr(*prattrs)]
      }]

      cls.map{|klass|
        round_num = klass.single_games.aggregate(:round.max) || 0
        {
          class_id: klass.id,
          rounds: (1..round_num).map{|x| rn = klass.round_name
            [if rn and rn[x.to_s] then
              rn[x.to_s]
            else
              "#{x}回戦"
            end]
        },
          user_results: result_sort(klass.single_games,user_games,round_num,prizes)
        }
      }
    end

    # 勝ち数の多い順に並べる
    def result_sort(games,user_games,round_num,prizes)
      temp_res = {}

      # 後で少しずつ取得するのは遅いのでまとめて取得
      users = Hash[games.contest_users.all(fields:[:id,:name]).map{|u|
        [u.id,u.name]}]

      users.keys.each{|uid|
        score = ["Z"] * round_num
        score_opt = ["Z"] * round_num # 同じ勝ち数の場合の順番
        user_games[uid].each_with_index{|m,index|
          (score[index],score_opt[index]) =
            case m[:result]
              when :win then ["A","A"]
              when :default_win then ["A","B"]
              when :lose then ["C","C"]
            end
            temp_res[uid] = {
              score: score,
              score_opt: score_opt
            }
        }
      }
      # 自分が負けた以降の順番は負けた相手の成績順になる
      games.all(result: :lose, order: :round.desc).each{|m|
        x = temp_res.find{|uid,v|users[uid] == m.opponent_name}
        if x then
          temp_res[m.contest_user_id][:score][m.round..-1] = x[1][:score][m.round..-1]
        end
      }
      temp_res.map{|uid,v|
        {user_id:uid}.merge(v)
      }.sort_by{|x|
        x[:score]+x[:score_opt]
      }.map{|x|
        uid = x[:user_id]
        r = {
          user_name: users[uid],
          game_results: user_games[uid]
        }
        if prizes.has_key?(uid) then
          r[:prize] = prizes[uid]
        end
        r 
      }
    end
    
    # 団体戦の結果
    def contest_results_team(evt)
      evt.result_classes.teams.map{|team|
        ops = team.opponents(order: :round.asc)
        round_ops = Hash[ops.map{|o|[o.round,o]}]
        max_round = ops.size
        temp = ops.games.group_by{|game| game.contest_user}
          .map{|user,results|
            res = Hash[results.map{|game|
              [game.contest_team_opponent.round,game]
            }]
            game_results = (1..max_round).map{|round|
              game = res[round]
              if game then
                game.select_attr(:opponent_name,:result,:score_str).merge({
                  opponent_belongs: game.select_attr(:opponent_order,:opponent_belongs)
                })
              else
                {result: "break"}
              end
            }
            r = {
              user_name: user.name,
              game_results: game_results
            }
            if user.prize.nil?.! then
              r[:prize] = user.prize.select_attr(:prize,:point_local)
            end
            r
          }
        hl = {team_name: team.name}
        if team.prize then
          hl[:team_prize] = team.prize
        end
        user_results = temp
        {
          class_id: team.contest_class_id,
          header_left: hl, 
          rounds: ops.to_enum.with_index(1).map{|x,i|[
            x.round_name  || "#{i}回戦",
            if x.kind == :single then "(個人戦)" else x.name end
        ]},
          user_results: user_results 
        }
      }
    end

    def result_summary(ev)
      cache = ev.result_cache
      r = ev.select_attr(:id,:name,:date)
      r.merge({
        user_count: ev.contest_user_count,
        win: if cache then cache.win else 0 end,
        lose: if cache then cache.lose else 0 end,
        prizes: if cache then cache.prizes else [] end
      })
    end
    get '/group/:id' do
      page = if params[:page].to_s.empty?.! then params[:page].to_i else 1 end
      group = EventGroup.get(params[:id].to_i)
      r = group.select_attr(:name,:description)
      chunks = group.events.all(order:[:date.desc]).chunks(EVENT_GROUP_PER_PAGE)
      list = chunks[page-1].map{|ev|
        result_summary(ev)
      }
      r.merge({list:list,cur_page:page,pages:chunks.size})
    end
  end
  get '/result' do
    haml :result
  end
  get '/result/excel/:id' do
    send_excel(Event.get(params[:id]))
  end
end
