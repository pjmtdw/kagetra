# -*- coding: utf-8 -*-
class MainApp < Sinatra::Base
  namespace '/api/result_ranking', auth: :user do
    def parse_month_date(s,is_end)
      begin
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
      rescue ArgumentError
        halt 400, { error_message: "日付の形式が不正です" }
      end
    end
    post '/search' do
      cond = {}
      eventcond = []
      meta = {}
      if @json["start"].to_s.empty?.! then
        sdate = parse_month_date(@json["start"],false)
        eventcond << Sequel.expr{ date >= sdate }
        meta[:start] = sdate
      end
      if @json["end"].to_s.empty?.! then
        edate = parse_month_date(@json["end"],true)
        eventcond << Sequel.expr{ date <= edate }
        meta[:end] = edate
      end
      meta[:filter] = @json["filter"]
      if @json["filter"] == "official" then
        eventcond << Sequel.expr(official:true)
      end
      if not eventcond.empty? then
        cond[:event_id] = Event.where(eventcond.inject(:&)).map(&:id)
      end
      if @json["filter"].to_s.empty?.! and @json["filter"] != "official" then
        cond[:class_rank] = ContestClass.serialization_map[:class_rank].call(@json["filter"].to_sym)
      end
      data = {}
      qbase = ContestUser.where(cond).distinct(:name).group(:name)
      ["key1","key2"].each{|key|
        ll = case @json[key]
        when "win"
          qbase.select(:name,Sequel.function(:sum,:win).coalesce_0.as("val"))
        when "contest_num"
          qbase.select(:name,Sequel.function(:count,1).as("val"),:name)
        when "win_percent"
          qbase.select(:name,
                       Sequel.function(:sum,:win).coalesce_0.as("sum_win"),
                       Sequel.function(:sum,:lose).coalesce_0.as("sum_lose")).map{|x|
            w = x[:sum_win]
            l = x[:sum_lose]
            percent = if w+l == 0 then 0 else ((w/(w+l).to_f)*100).to_i end
            {name:x.name,val:percent}
          }
        when "point"
          qbase.select(:name,Sequel.function(:sum,:point).coalesce_0.as("val"))
        when "point_local"
          qbase.select(:name,Sequel.function(:sum,:point_local).coalesce_0.as("val"))
        end
        sum = ll.map{|x|x[:val]}.sum
        meta[key] = {
          name: @json[key],
          sum: sum
        }
        data[key] = Hash[ll.map{|x|[x[:name],{key=>x[:val]}]}]
      }
      ranking = data["key1"].merge(data["key2"]){|key,oldval,newval|
        oldval.merge(newval)
      }.to_a.map{|v|
        { name: v[0], key1: v[1]["key1"], key2: v[1]["key2"] }
      }.sort_by{|v|
        [v[:key1] || 0, v[:key2] || 0]
      }.reverse
      # ランク付け
      rank = 0
      count = 1
      value = nil
      ranking.map! do |v|
        if v[:key1] == value
          count += 1
          v[:rank] = rank
        else
          rank += count
          count = 1
          value = v[:key1]
          v[:rank] = rank
        end
        v
      end
      { meta: meta, ranking: ranking }
    end
    get '/year' do
      minyear = Event.where(kind:Event.kind__contest).min(:date).year
      { minyear: minyear, maxyear: Date.today.year }
    end
  end
end
