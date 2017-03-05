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
      llbase = UserLoginLog.where{created_at > Time.now - 86400}.where(counted:true, user_id: (ranking_cur.map{|x|x[:user_id]}+[@user.id]))
      one_day = llbase.group_and_count(:user_id).to_hash(:user_id,:count)

      # 先月
      (py,pm) = Kagetra::Utils.inc_month(Date.today.year,Date.today.month,-1)
      c0 = Sequel.expr(year_month: UserLoginMonthly.year_month(py,pm))
      c1 = Sequel.expr{rank <= rank_max} | Sequel.expr(user_id: @user.id)
      ranking_prev = UserLoginMonthly.where(c0 & c1).order(Sequel.asc(:rank)).map{|x|x.select_attr(:user_id,:rank,:count)}
      myinfo = ranking_prev.find{|x|x[:user_id] == @user.id}
      prev = {ranking:ranking_prev,myinfo:myinfo}

      # 全部
      rank = 1
      prev_count = nil
      myinfo = nil
      ranking_total = []
      UserLoginMonthly.select(:user_id,Sequel.function(:sum,:count).as("sum_count")).group(:user_id).order(Sequel.desc(:sum_count)).to_enum.with_index(1){|x,index|
        uid = x[:user_id]
        count = x[:sum_count]
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

      uids = (ranking_cur+ranking_prev+ranking_total).map{|x|x[:user_id]}.uniq
      names.merge!(User.where(id:uids).to_hash(:id,:name))

      {cur:cur, prev:prev, total:total, names:names, one_day: one_day}
    end
    get '/weekly' do
      weekago = Time.now - 86400*7
      res = {}
      # 各DB固有のdate function使ってgroup byした方が速いので使えるのであればそちらを使う
      # TODO: PostgreSQLとSQLite特有の処理を書く -> case DB.adapter_scheme .. when .. end
      base = UserLoginLog.where(counted:true).where{created_at > weekago}
      tot = Hash.new{0}
      mylog = Hash.new{0}
      base.each{|x|
        tm = x.created_at.strftime("%Y-%m-%d %H")
        tot[tm] += 1
        if x.user_id == @user.id then
          mylog[tm] += 1
        end
      }
      res[:total] = tot
      res[:mylog] = mylog
      total_max = res[:total].values.max
      cur = Time.now
      dates = Hash.new{[]}
      while cur >= weekago
        s = cur.strftime("%Y-%m-%d %H")
        dates[cur.strftime("%m月%d日 (#{G_WEEKDAY_JA[cur.wday]})")] <<= {hour:cur.hour,total:res[:total][s]||0,mylog:res[:mylog][s]||0}
        cur -= 3600
      end
      {list:dates.to_a,total_max:total_max}
    end
    get '/total' do
      (fromy,fromm) = Kagetra::Utils.inc_month(Date.today.year,Date.today.month,-48)
      cond = Sequel.expr{ year_month >= UserLoginMonthly.year_month(fromy,fromm) } & Sequel.expr{ year_month < UserLoginMonthly.year_month(Date.today.year,Date.today.month)}
      res = {}
      UserLoginMonthly.where(cond).select(Sequel.function(:sum,:count).as("sum_count"),:year_month).group(:year_month).map{|x|
        res[x[:year_month]] ||= {}
        res[x[:year_month]][:count] = x[:sum_count]
      }
      rank_max = 5
      UserLoginMonthly.where(cond).where{ rank <= rank_max }.each{|x|
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
      @user.login_monthlies_dataset.where(cond).each{|x|
        res[x.year_month][:user] = x.select_attr(:count,:rank)
      }
      {list:res.to_a.sort_by{|k,v|k}.reverse}
    end
  end
end
