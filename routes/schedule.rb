class MainApp < Sinatra::Base
  namespace '/api/schedule' do
    def make_info(x)
      return unless x
      base = x.select_attr(:names)
      base[:is_holiday] = true if x.holiday
      base
    end
    def make_item(x)
      return unless x
      base = x.select_attr(:id, :kind, :name, :place, :start_at, :end_at, :description)
      base[:emphasis] = {}
      unless x.emphasis.empty?
        x.emphasis.each{|k| base[:emphasis][k] = true}
      end
      base
    end
    def make_event(x)
      return unless x
      x.select_attr(:id, :name)
    end
    get '/cal/:year-:mon' do
      year = params[:year].to_i
      mon = params[:mon].to_i

      first = Date.new(year, mon, 1)
      last = first.next_month - 1
      from = first - first.wday
      weeks = []
      while from <= last
        weeks.push((from..(from + 6)).to_a)
        from += 7
      end

      cbase = {}
      cbase[:where] = if @public_mode then { public: true } end
      cbase[:order] = [Sequel.asc(:start_at), Sequel.asc(:end_at)]

      (day_infos, items, events) = [
        [ScheduleDateInfo, :info, :make_info, Hash, {}],
        [ScheduleItem, :item, :make_item, Array, cbase],
        [Event, :event, :make_event, Array, cbase]
      ].map{|model, sym, func, obj, cond|
        from = weeks[0][0]
        to = weeks[-1][-1]
        query = model.where{(date >= from) & (date < to)}
        if cond[:where] then
          query = query.where(cond[:where])
        end
        if cond[:order] then
          query = query.order(*cond[:order])
        end
        query.all.each_with_object(if obj == Array then Hash.new{[]} else {} end){|x, h|
          if obj == Array then
            h[x.date] <<= send(func, x)
          else
            h[x.date] = send(func, x)
          end
        }
      }

      today = Date.today.day
      weeks.map!{|week|
        week.map{|date|
          {
            year: date.year,
            month: date.mon,
            date: date.day,
            day: date.wday,
            toman: date.mon === mon,
            today: date.day === today,
            info: day_infos[date] || {},
            items: items[date] || [],
            events: events[date] || [],
          }
        }
      }
      weeks
    end
    get '/get/:year-:mon-:day' do
      (year, mon, day) = [:year, :mon, :day].map{|x| params[x].to_i}
      date = Date.new(year, mon, day)
      {
        info: make_info(ScheduleDateInfo.first(date: date)),
        items: ScheduleItem.where(date: date).order(Sequel.asc(:start_at),Sequel.asc(:end_at)).map{|x| make_item(x)}
      }
    end
    post '/copy', auth: :user do
      item_cache = {}
      @json.each{|d, items|
        date = Date.parse(d)
        items.each{|id|
          if not item_cache[id]
            item_cache[id] = ScheduleItem[id]
          end
          ScheduleItem.create(item_cache[id]
            .select_attr
            .merge(owner: @user, date: date)
            .delete_if{|x| [:id, :created_at, :updated_at].include?(x)}
          )
        }
      }
      return
    end
    post '/update_holiday', auth: :user do
      with_update{
        @json.each{|day,obj|
          ScheduleDateInfo.update_or_create(date:Date.parse(day)){|item|
            item.names = obj["names"]
            item.holiday = obj["holiday"]
          }
        }
      }
    end
    def update_or_create(id)
      old_item = if not id.nil? then ScheduleItem[id] end
      if not id.nil? and old_item.nil? then
        raise Exception.new("schedule_item not found:#{id}")
      end
      date = if id.nil? then
        Date.new(@json['year'], @json['mon'], @json['day'])
      end
      emph = if old_item.nil? then
               []
             else
               old_item.emphasis
             end
      [:name, :place, :start_at, :end_at].each{|s|
        if @json['emphasis'][s.to_s] then
          emph << s
        elsif not @json['emphasis'][s.to_s].nil?
          emph.reject!{|x| x == s}
        end
      }
      # TODO: make_deserialized_data 使っているのはここだけだし実際に使う意味はないっぽいので廃止
      data = { emphasis: emph }.merge(
          ScheduleItem.make_deserialized_data(
            @json.select_attr('name', 'place', 'description', 'start_at', 'end_at', 'public')
          )
      )
      if @json.has_key?('kind') then
        data[:kind] = @json['kind']
      end
      if old_item.nil? then
        data[:owner_id] = @user.id
      end
      if date then
        data[:date] = date
      end
      if old_item.nil? then
        ScheduleItem.create(data)
      else
        old_item.update(data)
      end
    end
    def make_detail_item(x)
      r = x.select_attr(:id, :start_at, :end_at, :name, :place, :description, :public, :kind)
      r[:emphasis] = {}
      x.emphasis.each{|e|
        r[:emphasis][e] = true
      }
      r[:editable] = @user && (@user.admin or @user.sub_admin or @user.id == x.owner_id)
      r
    end
    get '/detail/item/:id' do
      make_detail_item(ScheduleItem[params[:id]])
    end
    post '/detail/item', auth: :user do
      with_update{
        update_or_create(nil)
      }
    end
    put '/detail/item/:id' do
      with_update{
        update_or_create(params[:id])
      }
    end
    delete '/detail/item/:id' do
      with_update{
        ScheduleItem[params[:id].to_i].destroy
      }
    end
    get '/detail/:year-:mon-:day' do
      (year, mon, day) = [:year, :mon, :day].map{|x| params[x].to_i}
      date = Date.new(year, mon, day)
      append_cond = lambda{|model|
        model = model.where(date: date)
        if @public_mode then
          model = model.where(public: true)
        end
        model.order(Sequel.asc(:start_at), Sequel.asc(:end_at))
      }
      items = append_cond.call(ScheduleItem).map{|x|
        make_detail_item(x)
      }
      events = append_cond.call(Event).map{|x|
        x.select_attr(:id, :name, :place, :comment_count, :start_at, :end_at, :map_bookmark_id)
      }
      {items: items, events: events}
    end

    SCHEDULE_PANEL_DAYS = 3
    get '/panel', auth: :user do
      today = Date.today
      append_cond = lambda{|klass|
        klass.where{ (date >= today) & (date < today + SCHEDULE_PANEL_DAYS) }
      }
      append_order = lambda{|dataset|
        dataset.order(Sequel.asc(:start_at),Sequel.asc(:end_at))
      }
      arr = (0...SCHEDULE_PANEL_DAYS).map{|i|
        d = today + i
        {year: d.year, mon: d.mon, day: d.day}
      }
      [
        [ScheduleDateInfo,:info,:make_info,Hash,lambda{|x|x}],
        [ScheduleItem,:item,:make_item,Array,append_order],
        [Event,:event,:make_event,Array,append_order]
      ].each{|klass,sym,func,obj,order_func|
        dataset = order_func.call(append_cond.call(klass))
        dataset.each{|x|
          p = arr[x.date-today]
          p[sym] ||= obj.new
          if obj == Array then
            p[sym] <<= send(func,x)
          else
            p[sym] = send(func,x)
          end
        }
      }
      arr
    end


    SCHEDULE_EVENT_DONE_PER_PAGE = 40
    get '/ev_done', auth: :user do
      page = if params[:page].to_s.empty?.! then params[:page].to_i else 1 end
      chunk = Event.where(Sequel.~(kind: Event.kind__contest),done:true)
                   .order(Sequel.desc(:updated_at),Sequel.desc(:id))
                   .paginate(page,SCHEDULE_EVENT_DONE_PER_PAGE)
      pages = chunk.page_count
      list = chunk.map{|x|
        x.select_attr(:id,:name,:place,:comment_count,:start_at,:end_at,:date)
         .merge({has_new_comment:x.has_new_comment(@user)})
      }
      {
        list:list,
        pages: pages,
        cur_page: page
      }
    end
  end
end
