# -*- coding: utf-8 -*-
class MainApp < Sinatra::Base
  EVENTS_PER_PAGE = 4
  HALF_PAGE = EVENTS_PER_PAGE/2
  namespace '/api/result' do
    get '/contest/:id' do
      cond = Event.all(kind: :contest, :date.lte => Date.today)
      evt = (cond & Event.all(
              if params[:id] == "latest" then
                {order: [:date.desc]}
              else
                {id: params[:id].to_i}
              end
            )).first
      (pre,post) = [[:lt,:desc],[:gt,:asc]].map{|p,q|
        (cond & (Event.all(date:evt.date, :id.send(p) => evt.id) | Event.all(:date.send(p) => evt.date)))
        .all(order: [:date.send(q), :id.send(q)])[0...EVENTS_PER_PAGE]
      }
      # execute query and obtain list
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

      gr = evt.event_group
      group = if gr then gr.events(:date.lte => Date.today, order:[:date.desc])
                .map{|x| x.select_attr(:id,:name,:date)} else [] end

      evt.select_attr(:id,:name,:num_teams,:date).merge({
        list: list,
        group: group,
        event_results: event_results(evt)
      })
    end
    def event_results(evt)
      # 後で少しずつ取得するのは遅いのでまとめて取得
      games = evt.result_classes.single_games
      round_num = games.aggregate(:round.max)
      user_games = games.map{|gm|
        [gm.user.id,gm.select_attr(:result,:opponent_name,:opponent_belongs,:score_str)]
      }.each_with_object(Hash.new{[]}){|(uid,attrs),h|
        h[uid] <<= attrs
      }
      evt.result_classes.map{|klass|
        {
          name: klass.class_name,
          user_results: result_sort(klass.single_games,user_games,round_num)
        }
      }
    end

    # 勝ち数の多い順に並べる
    def result_sort(games,user_games,round_num)
      temp_res = {}

      # 後で少しずつ取得するのは遅いのでまとめて取得
      users = Hash[games.users.map{|u|
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
          temp_res[m.user.id][:score][m.round..-1] = x[1][:score][m.round..-1]
        end
      }
      temp_res.map{|uid,v|
        {user_id:uid}.merge(v)
      }.sort_by{|x|
        x[:score]+x[:score_opt]
      }.map{|x|
        {
          user_name: users[x[:user_id]],
          game_results: user_games[x[:user_id]]
        }
      }
    end

  end
  get '/result' do
    user = get_user
    haml :result, locals:{user: user}
  end
end
