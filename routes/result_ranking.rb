# -*- coding: utf-8 -*-
class MainApp < Sinatra::Base
  namespace '/api/result_ranking' do
    def parse_month_date(s,is_end)
      if /^(\d+)$/ =~ s then
        d = Date.parse(s+"-1-1")
        if is_end then
          d.next_year - 1
        else
          d
        end
      elsif /^(\d+)-(\d+)$/ =~ s then
        d = Date.parse(s+"-1")
        if is_end then
          d.next_month - 1
        else
          d
        end
      else
        Date.parse(s)
      end
    end
    post '/search' do
      cond = {}
      eventcond = {}
      if @json["start"].to_s.empty?.! then
        eventcond[:date.gte] = parse_month_date(@json["start"],false)
      end
      if @json["end"].to_s.empty?.! then
        eventcond[:date.lte] = parse_month_date(@json["end"],true)
      end
      if @json["filter"] == "official" then
        eventcond[:official] = true
      end
      if not eventcond.empty? then
        cond[:event_id] = Event.all(eventcond.merge({fields:[:id]})).map{|x|x.id}
      end
      if @json["filter"].to_s.empty?.! and @json["filter"] != "official" then
        cond[:class_rank] = @json["filter"].to_sym
      end
      meta = {}
      data = {}
      ["key1","key2"].each{|key|
        ll = case @json[key]
        when "win"
          ContestUser.aggregate(cond.merge({fields:[:name,:win.sum],unique:true}))
        when "contest_num"
          ContestUser.aggregate(cond.merge({fields:[:name,:id.count],unique:true}))
        when "win_percent"
          ContestUser.aggregate(cond.merge({fields:[:name,:win.sum,:lose.sum],unique:true})).map{|name,win,lose|
            w = win || 0
            l = lose || 0
            percent = if w+l == 0 then 0 else ((w/(w+l).to_f)*100).to_i end
            [name,percent]
          }
        when "point"
          ContestUser.aggregate(cond.merge({fields:[:name,:point.sum],unique:true}))
        when "point_local"
          ContestUser.aggregate(cond.merge({fields:[:name,:point_local.sum],unique:true}))
        end
        sum = ll.map{|x,y|y||0}.sum
        meta[key] = {
          name: @json[key],
          sum: sum
        }
        data[key] = Hash[ll.map{|x,y|[x,{key=>(y||0)}]}]
      }
      ranking = data["key1"].merge(data["key2"]){|key,oldval,newval|
        oldval.merge(newval)
      }.to_a.sort_by{|name,d|
        [d["key1"] || 0, d["key2"] || 0]
      }.reverse
      {meta:meta,ranking:ranking}
    end
  end
  get '/result_ranking' do
    @minyear = Event.aggregate(:date.min,kind:[:contest]).year
    haml :result_ranking
  end
end
