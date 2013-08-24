# -*- coding: utf-8 -*-
class MainApp < Sinatra::Base
  namespace '/api/login_log' do
    get '/ranking' do
      names = {@user.id => @user.name}

      rank_max = 20

      # 今月
      ranking = UserLoginMonthly.calc_rank(Date.today.year,Date.today.month)
      myinfo = ranking.find{|x|x[:user_id] == @user.id}
      ranking_cur = ranking[0...rank_max]
      cur = {ranking:ranking_cur,myinfo:myinfo}

      # 24時間
      one_day = Hash[UserLoginLog.aggregate(:user_id,:id.count,:created_at.gt => DateTime.now-1, counted:true, user_id:(ranking_cur.map{|x|x[:user_id]}+[@user.id]))]

      # 先月
      (py,pm) = Kagetra::Utils.inc_month(Date.today.year,Date.today.month,-1)
      c0 = UserLoginMonthly.all(year_month: UserLoginMonthly.year_month(py,pm))
      c1 = UserLoginMonthly.all(:rank.lte => rank_max) | UserLoginMonthly.all(user_id: @user.id)
      ranking_prev = (c0 & c1).all(order: [:rank.asc]).map{|x|x.select_attr(:user_id,:rank,:count)}
      myinfo = ranking_prev.find{|x|x[:user_id] == @user.id}
      prev = {ranking:ranking_prev,myinfo:myinfo}

      # 全部
      rank = 1
      prev_count = nil
      myinfo = nil
      ranking_total = []
      UserLoginMonthly.aggregate(:user_id,:count.sum).sort_by{|uid,count|count}.reverse.to_enum.with_index(1){|(uid,count),index|
        if count != prev_count
          prev_count = count
          rank = index
        end
        if uid == @user.id
          myinfo = {user_id: uid, count: count, rank:rank}
        end
        if rank > rank_max and myinfo
          break
        end
        if rank <= rank_max
          ranking_total << {user_id: uid, count: count, rank: rank}
        end
      }
      total = {ranking:ranking_total,myinfo:myinfo}

      names.merge!(Hash[User.all(id:(ranking_cur+ranking_prev+ranking_total).map{|x|x[:user_id]}.uniq).map{|x|[x.id,x.name]}])

      {cur:cur, prev:prev, total:total, names:names, one_day: one_day}
    end
    get '/weekly' do
      weekago = Time.now - 86400*7
      adapter = repository(:default).adapter
      res = {}
      # 各DB固有のdate function使ってgroup byした方が速いので使えるのであればそちらを使う
      # TODO: PostgreSQLとSQLite特有の処理を書く
      case adapter.options["adapter"]
      when "mysql"
        base = ->(where){"SELECT DATE_FORMAT(created_at,'%Y-%m-%d %H') `time`, count(id) `count` FROM user_login_logs WHERE counted = 1 and created_at > '#{weekago.strftime("%Y-%m-%d %H:%M:%S")}' #{where} GROUP BY `time`"} 
        sel = adapter.select(base.call(""))
        res[:total] = Hash[sel.map{|x|[x.time,x.count]}]
        sel = adapter.select(base.call("AND user_id=#{@user.id}"))
        res[:mylog] = Hash[sel.map{|x|[x.time,x.count]}]
      else
        tot = Hash.new{0}
        mylog = Hash.new{0}
        UserLoginLog.all(fields:[:created_at,:user_id], :created_at.gt => weekago, counted:true).each{|x|
          tm = x.created_at.strftime("%Y-%m-%d %H")
          tot[tm] += 1
          if x.user_id == @user.id then
            mylog[tm] += 1
          end
        }
        res[:total] = tot
        res[:mylog] = mylog
      end
      cur = Time.now
      dates = Hash.new{[]}
      while cur >= weekago
        s = cur.strftime("%Y-%m-%d %H")
        dates[cur.strftime("%m月%d日 (#{G_WEEKDAY_JA[cur.wday]})")] <<= {hour:cur.hour,total:res[:total][s]||0,mylog:res[:mylog][s]||0}
        cur -= 3600
      end
      {list:dates.to_a}
    end
    get '/total' do
      (fromy,fromm) = Kagetra::Utils.inc_month(Date.today.year,Date.today.month,-48)
      cond = {:year_month.gte => UserLoginMonthly.year_month(fromy,fromm),:year_month.lt => UserLoginMonthly.year_month(Date.today.year,Date.today.month)}
      res = {}
      UserLoginMonthly.all.aggregate(:count.sum,cond.merge({fields:[:year_month],unique:true})).map{|ym,count|
        res[ym] ||= {}
        res[ym][:count] = count
      }
      rank_max = 5
      UserLoginMonthly.all(cond.merge({:rank.lte => rank_max})).each{|x|
        res[x.year_month][:top] ||= {}
        # 同順位があったときの対処
        rank = x.rank
        loop{
          if not res[x.year_month][:top].has_key?(rank) then
            res[x.year_month][:top][rank] = x.count
            break
          end
          rank += 1
          break if rank > rank_max
        }
      }
      @user.login_monthlies.all(cond).each{|x|
        res[x.year_month][:user] = x.select_attr(:count,:rank)
      }
      {list:res.to_a.sort_by{|k,v|k}.reverse}
    end
  end
  get '/login_log' do
    haml :login_log
  end
end
