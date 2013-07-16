# -*- coding: utf-8 -*-
class MainApp < Sinatra::Base 
  namespace '/api/login_log' do
    get '/ranking' do
      ranking = UserLoginMonthly.calc_rank(Date.today.year,Date.today.month)
      ranking_top = ranking[0...20]
      names = Hash[User.all(id:ranking_top.map{|x|x[:user_id]}).map{|x|[x.id,x.name]}]
      names[@user.id] = @user.name
      myinfo = ranking.find{|x|x[:user_id] == @user.id}
      {ranking:ranking_top, myinfo:myinfo , names:names}
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
