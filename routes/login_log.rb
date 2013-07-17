# -*- coding: utf-8 -*-
class MainApp < Sinatra::Base 
  namespace '/api/login_log' do
    get '/ranking' do
      names = {@user.id => @user.name}

      rank_max = 20

      ranking = UserLoginMonthly.calc_rank(Date.today.year,Date.today.month)
      myinfo = ranking.find{|x|x[:user_id] == @user.id}
      ranking_cur = ranking[0...rank_max]
      cur = {ranking:ranking_cur,myinfo:myinfo}
      names.merge!(Hash[User.all(id:ranking_cur.map{|x|x[:user_id]}).map{|x|[x.id,x.name]}])

      (py,pm) = Kagetra::Utils.inc_month(Date.today.year,Date.today.month,-1)
      c0 = UserLoginMonthly.all(year_month: UserLoginMonthly.year_month(py,pm))
      c1 = UserLoginMonthly.all(:rank.lte => rank_max) | UserLoginMonthly.all(user_id: @user.id)
      ranking_prev = (c0 & c1).all(order: [:rank.asc]).map{|x|x.select_attr(:user_id,:rank,:count)}
      myinfo = ranking_prev.find{|x|x[:user_id] == @user.id}
      prev = {ranking:ranking_prev,myinfo:myinfo}
      names.merge!(Hash[User.all(id:ranking_prev.map{|x|x[:user_id]}).map{|x|[x.id,x.name]}])

      {cur:cur, prev:prev, names:names}
    end
    get '/weekly' do
      # TODO
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
