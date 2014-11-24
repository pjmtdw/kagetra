# -*- coding: utf-8 -*-
class MainApp < Sinatra::Base
  PROMOTION_RECENT_MAX_DAY = 365
  namespace '/api/result_promotion' do
    get '/recent' do
      event_ids = Event.where(kind:Event.kind__contest,team_size:1).where{Sequel.expr(:date) >= (Date.today - PROMOTION_RECENT_MAX_DAY)}.map(&:id)
      list = ContestPromotionCache.where(event_id:event_ids,promotion:ContestPrize.promotion__rank_up).map{|prom|
        cuser = prom.contest_user
        u = cuser.user
        attr_values = if u.nil? then [] else u.attrs.map(&:value).flatten.map{|x|x[:id]} end
        {
          class_name: prom.class_name,
          name: prom.user_name,
          user_id: cuser.user_id,
          prize: prom.prize,
          event:{name:prom.event_name,date:prom.event_date,id:prom.event_id},
          attr_values:attr_values
        }
      }.sort_by{|x|
        x[:event][:date]
      }.reverse
      attrs = UserAttributeKey.where(name:CONF_PROMOTION_ATTRS).order(Sequel.asc(:index)).map{|x|
        [x.name,x.attr_values.map{|y|[y.value,y.id]}]
      }
      {list:list,attrs:attrs}
    end
    get '/ranking' do
      pass if params["mode"] == "list" and params["to"] == "a_champ"
      prev_rank = ->(s){(s.sub('prom_','').ord+1).chr.to_sym}
      previous_april = ->(dt){Date.new(if dt.month <= 3 then dt.year - 1 else dt.year end,4,1)}
      bottom_rank = case params["from"]
                   when "debut" then :g
                   else prev_rank.call(params["from"])
                   end
      top_rank = case params["to"]
                 when "a_champ" then :a
                 else prev_rank.call(params["to"])
                 end
      ranks = (top_rank..bottom_rank).map{|x|ContestClass.serialization_map[:class_rank].call(x)}
      names = ContestPromotionCache.distinct(:user_name).where(class_rank:ContestClass.serialization_map[:class_rank].call(top_rank)).map(&:user_name)
      query = ContestPromotionCache.where(user_name:names,class_rank:ranks)
      res = Hash.new{{contests:0,start:nil,end:nil}}
      query.each{|x|
        next if params["mode"] != "list" and x.class_rank == :a and x.a_champ_count != 1
        r = res[x.user_name]
        if params["from"] == "debut" or x.class_rank != bottom_rank
          r[:contests] += x.contests
        end
        info = x.select_attr(:event_date,:event_name,:event_id,:prize)
        if x.class_rank == top_rank
          r[:end] = info
        end
        if params["from"] == "debut"
          dt = if r[:start].nil? then x.debut_date else [x.debut_date,r[:start][:event_date]].min end
          r[:start] = {event_date:previous_april.call(dt)}
        elsif x.class_rank == bottom_rank
          r[:start] = info
        end
        res[x.user_name] = r
      }
      list = res.to_a.map{|k,v|
        if v[:start].nil? or v[:end].nil? then
          nil
        else
          edate = v[:end][:event_date]
          sdate = v[:start][:event_date]
          v[:days] = (edate - sdate).to_i
          v[:days_str] = Kagetra::Utils.date_diff_str(edate,sdate)
          v[:user_name] = k
          v
        end
      }.compact
      return [] if list.empty?
      median = ""
      case params["mode"]
      when "days"
        list.sort_by!{|x|[x[:days],x[:contests]]}
        median = list.map{|x|x[:days]}.median.to_s +  "日"
      when "contests"
        list.sort_by!{|x|[x[:contests],x[:days]]}
        median = list.map{|x|x[:contests]}.median.to_s +  "大会"
      when "list"
        list.sort_by!{|x|x[:end][:event_date]}
        list.reverse!
      end
      {display:"ranking",list:list,median:median}
    end
    get '/ranking' do
      # A級優勝一覧(一つ上の/rankingでpassされるとここに辿り付く)
      query = ContestPromotionCache.where(class_rank: ContestClass.class_rank__a,
                                          promotion: ContestPrize.promotion__a_champ)
                                    .order(Sequel.asc(:event_date))
      nth_champ = 0
      list = query.map{|x|
        info = if x.a_champ_count == 1 then
                 nth_champ += 1
                 {nth_champ:nth_champ}
               else {} end
        info.merge(x.select_attr(:event_date,:event_name,:event_id,:user_name,:a_champ_count))
      }.reverse
      {display:"a_champ",list:list}
    end
  end
end
