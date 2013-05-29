class MainApp < Sinatra::Base
  namespace '/api/schedule' do
    get '/cal' do
      year = params[:year].to_i
      mon = params[:mon].to_i
      fday = Date.new(year,mon,1)
      lday = fday >> 1
      month_day = (lday - fday).to_i
      before_day = fday.cwday % 7
      after_day = 7 - lday.cwday
      today = Date.today.day
      day_infos = ScheduleDateInfo
        .all_month(:date,year,mon)
        .each_with_object({}){|x,h|
          base = {
            names: x.names
          }
          base[:is_holiday] = true if x.holiday
          h[x.date.day] = base
        }
      items = ScheduleItem.all_month(:date,year,mon)
        .each_with_object(Hash.new{[]}){|x,h|
          base = {
            type: x.type,
            title: x.title,
            place: x.place
          }
          base[:start_at] = x.start_at if x.start_at
          base[:end_at] = x.end_at if x.end_at
          base[:emphasis] = x.emphasis if x.emphasis.empty?.!
          p base.keys()
          h[x.date.day] <<= base
        }
      {
        year: year,
        mon: mon,
        today: today,
        month_day: month_day,
        before_day: before_day,
        after_day: after_day,
        day_infos: day_infos,
        items: items
      }
    end
  end
  get '/schedule' do
    haml :schedule
  end
end
