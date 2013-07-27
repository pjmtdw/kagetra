# -*- coding: utf-8 -*-
class MainApp < Sinatra::Base
  PROMOTION_MAX_DAY = 365
  RESULT_RECORD_DEFAULT_MAX = 30
  namespace '/api/result_misc' do
    get '/year/:year' do
      minyear = Event.aggregate(:date.min,kind:[:contest]).year
      year = params[:year].to_i
      sday = Date.new(year,1,1)
      eday = Date.new(year+1,1,1)
      list = Event.all(:date.gte => sday, :date.lt => eday, done: true, kind:[:contest], order:[:date.desc]).map{|x|
        result_summary(x)
      }
      {list:list,minyear:minyear,maxyear:Date.today.year,curyear:year}
    end
    get '/promotion' do
      event_ids = Event.all(:date.gte => Date.today - PROMOTION_MAX_DAY, fields:[:id]).map{|x|x.id}
      list = ContestResultCache.all(event_id:event_ids,:prizes.not=>[]).map{|x|
        x.prizes.select{|y|
          y["type"] == "person" and y["promotion"] == "rank_up"
        }.map{|y|
          u = User.get(y["user_id"])
          attr_values = if u.nil? then [] else u.attrs.value.map{|x|x[:id]} end 
          y.select_attr("class_name","name","prize","user_id").merge({event:x.event.select_attr(:name,:date),attr_values:attr_values})
        }
      }.flatten.sort_by{|x|
        x[:event][:date]
      }.reverse
      attrs = UserAttributeKey.all(name:G_PROMOTION_ATTRS,order:[:index.asc]).map{|x|
        [x.name,x.values.map{|y|[y.value,y.id]}]
      }
      {list:list,attrs:attrs}
    end
    post '/search_name' do
      query = params[:q]
      list1 = ContestUser.aggregate(fields:[:name,:id.count],:name.like=>"#{query}%",unique:true).sort_by{|x,y|y}.reverse.map{|x,y|
        x
      }
      list2 = ContestGame.aggregate(fields:[:opponent_name,:id.count],:opponent_name.like=>"#{query}%",unique:true).sort_by{|x,y|y}.reverse.map{|x,y|
        x
      }
      results = (list1+list2).uniq
      {results:results}

    end

    post '/record' do
      name = @json["name"]
      if name == "myself" then
        name = @user.name
      end

      # raw query 使わないと1秒近くかかる
      cusers_all = repository(:default).adapter.select("SELECT id FROM contest_users WHERE name = '#{name}'")
      games_my = if cusers_all.empty? then [] else repository(:default).adapter.select("SELECT id,event_id FROM contest_games WHERE contest_user_id IN (#{cusers_all.join(',')})") end

      # 一つの大会で敵味方両方で出てる場合は味方のみを取得する(同会対決とかなので)
      cond = if games_my.empty? then "" else "AND event_id NOT IN(#{games_my.map{|x|x.event_id}.join(',')})" end
      
      games_op = repository(:default).adapter.select("SELECT id,event_id FROM contest_games WHERE opponent_name = '#{name}' #{cond}")

      eids = (games_my.map{|x|x.event_id} + games_op.map{|x|x.event_id}).uniq
      (mindate,maxdate) = Event.aggregate(fields:[:date.min,:date.max],id:eids)

      events = Event.all(fields:[:id,:name,:date],id:eids,order:[:date.desc])[0..RESULT_RECORD_DEFAULT_MAX]

      cusers = if events.empty? then [] else repository(:default).adapter.select("SELECT id FROM contest_users where name = '#{name}' AND event_id IN (#{events.map{|x|x.id}.join(',')})") end

      # 年ごとの集計
      aggr = events.group_by{|x|
        x.date.year
      }.map{|y,x|
        eids = x.map{|z|z.id}
        # 勝ち数負け数ポイント(味方として出場した場合)
        res = ContestUser.aggregate(fields:[:win.sum,:lose.sum,:point.sum,:point_local.sum],event_id:eids,id:cusers) || [0,0,0,0]
        if not games_op.empty? then
          # 勝ち数負け数(敵として出場した場合)
          c = {event_id:eids,id:games_op.map{|z|z.id}}
          res[0] ||= 0 ; res[1] ||= 0
          res[0] += ContestGame.all(c.merge({result: :lose})).count
          res[1] += ContestGame.all(c.merge({result: :win})).count
        end
        res
      }



      # 入賞
      prizes = Hash[ContestPrize.all(contest_user_id:cusers).map{|x|
          [x.contest_class.event_id,x.select_attr(:prize,:point,:point_local,:promotion)]
      }]
      my_ids = games_my.map{|x|x.id}
      op_ids = games_op.map{|x|x.id}

      my_belongs = {}
      class_info = {}
      games = ContestGame.all(event_id:events.map{|x|x.id},id:my_ids+op_ids).map{|x|
        is_op = op_ids.include?(x.id)
        res = {}

        # 回戦と相手の所属
        if x.type == :single then
          res.merge!(x.select_attr(:round))
          if not class_info.has_key?(x.event_id)
            class_info[x.event_id] = x.contest_class.select_attr(:class_name,:round_name)
          end
          if is_op then
            if not my_belongs.has_key?(x.event_id) then
              my_belongs[x.event_id] = x.opponent_belongs
            end
          else
            res.merge!(x.select_attr(:opponent_belongs))
          end
        else
          op_team = x.contest_team_opponent
          my_team = op_team.contest_team
          if not class_info.has_key?(x.event_id)
            class_info[x.event_id] = {class_name:my_team.contest_class.class_name,round_name:{}}
          end
          class_info[x.event_id][:round_name][op_team.round] = op_team.round_name
          res.merge!({round:op_team.round})
          if not my_belongs.has_key?(x.event_id) then
            my_belongs[x.event_id] = if is_op then op_team.name else my_team.name end
          end
          res[:opponent_belongs] = if is_op then my_team.name else op_team.name end
        end

        # 試合の勝敗を入れ替え
        if is_op then
           res[:result] = 
             case x.result
             when :win then :lose
             when :lose then :win
             else x.result
             end
           res[:opponent_name] = x.contest_user.name

         else
           res[:result] = x.result
           res[:opponent_name] = x.opponent_name
        end
        res.merge(x.select_attr(:event_id,:score_str))
      }
      res_games = Hash[games.group_by{|x|x[:event_id]}.map{|eid,arr|
        r = Hash[arr.map{|x|[x[:round],x]}]
        [eid,r]
      }]

      op_events = games_op.map{|x|x.event_id}.uniq
      res_events = events.map{|x|
        r = x.select_attr(:name,:date)
        r[:is_op] = op_events.include?(x.id)
        [x.id,r]
      }
      {
        name: name,
        mindate: mindate,
        maxdate: maxdate,
        games: res_games,
        events: res_events,
        prizes: prizes,
        my_belongs: my_belongs,
        class_info: class_info,
        aggr: aggr
      }
    end

  end
  get '/result_list' do
    haml :result_list
  end
  get '/result_promotion' do
    haml :result_promotion
  end
  get '/result_record' do
    haml :result_record
  end
end
