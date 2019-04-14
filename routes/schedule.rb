class MainApp < Sinatra::Base
  namespace '/api/schedule' do
    post '/copy', private:true do
      item_cache = {}
      @json.each{|d, items|
        date = Date.parse(d)
        items.each{|id|
          if not item_cache[id]
            item_cache[id] = ScheduleItem[id]
          end
          ScheduleItem.create(item_cache[id].select_attr
          .merge(
            owner:@user,
            date:date)
          .delete_if{|x|[:id,:created_at,:updated_at].include?(x)})
        }
      }
    end

    post '/update_holiday', private:true do
      with_update{
        @json.each{|day,obj|
          ScheduleDateInfo.update_or_create(date:Date.parse(day)){|item|
            item.names = obj["names"]
            item.holiday = obj["holiday"]
          }
        }
      }
    end
    def update_or_create(id, user, json)
      old_item = if not id.nil? then ScheduleItem[id] end
      if not id.nil? and old_item.nil? then
        raise Exception.new("schedule_item not found:#{id}")
      end
      date = if id.nil? then
        Date.new(json["year"],json["mon"],json["day"])
      end
      emph = if old_item.nil? then
               []
             else
               old_item.emphasis
             end
      [:name,:place,:start_at,:end_at].each{|s|
        key = "emph_#{s}"
        if json.has_key?(key) then
          if json[key] then
            emph << s
          else
            emph.reject!{|x|x==s}
          end
        end
      }
      # TODO: make_deserialized_data 使っているのはここだけだし実際に使う意味はないっぽいので廃止
      #       あとその下のhas_key?("kind") の部分もすっきりさせたい
      data = { emphasis: emph }.merge(
          ScheduleItem.make_deserialized_data(
            json.select_attr("name","place","description","start_at","end_at","public")))
      if json.has_key?("kind") then
        data[:kind] = json["kind"]
      end
      if old_item.nil? then
        data[:owner_id] = user.id
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
      r = x.select_attr(:id,:start_at,:end_at,:name,:place,:description,:public,:kind)
      x.emphasis.each{|e|
        r["emph_#{e}".to_sym] = true
      }
      r[:editable] = @user && (@user.admin or @user.sub_admin or @user.id == x.owner_id)
      r
    end
    get '/detail/item/:id' do
      make_detail_item(ScheduleItem[params[:id]])
    end
    post '/detail/item',private:true do
      with_update{
        update_or_create(nil, @user, @json)
      }
    end
    put '/detail/item/:id' do
      with_update{
        update_or_create(params[:id], @user, @json)
      }
    end
    delete '/detail/item/:id' do
      with_update{
        ScheduleItem[params[:id].to_i].destroy
      }
    end
    get '/detail/:year-:mon-:day' do
      (year,mon,day) = [:year,:mon,:day].map{|x|params[x].to_i}
      date = Date.new(year,mon,day)
      append_cond = lambda{|klass|
        klass = klass.where(date:date)
        if @public_mode then
          klass = klass.where(public:true)
        end
        klass.order(Sequel.asc(:start_at),Sequel.asc(:end_at))
      }
      list = append_cond.call(ScheduleItem).map{|x|
        make_detail_item(x)
      }
      events = append_cond.call(Event).map{|x|
        x.select_attr(:id,:name,:place,:comment_count,:start_at,:end_at,:map_bookmark_id)
      }
      info = ScheduleDateInfo.first(date:date)
      day_infos = if info then info.select_attr(:names,:holiday) end
      {year: year, mon: mon, day: day, list: list, events: events, day_infos: day_infos}
    end
    def make_info(x)
      return unless x
      base = x.select_attr(:names)
      base[:is_holiday] = true if x.holiday
      base
    end
    def make_item(x)
      return unless x
      base = x.select_attr(:id,:kind,:name,:place,:start_at,:end_at,:public,:description)
      base[:emphasis] = x.emphasis if x.emphasis.empty?.!
      base
    end
    def make_event(x)
      return unless x
      x.select_attr(:name,:public)
    end
    get '/get/:year-:mon-:day' do
      (year,mon,day) = [:year,:mon,:day].map{|x|params[x].to_i}
      date = Date.new(year,mon,day)
      {
        year: year,
        mon: mon,
        day: day,
        info: make_info(ScheduleDateInfo.first(date:date)),
        item: ScheduleItem.where(date:date).order(Sequel.asc(:start_at),Sequel.asc(:end_at)).map{|x|make_item(x)}
      }
    end

    SCHEDULE_PANEL_DAYS = 3
    get '/panel',private:true do
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


    get '/cal/:year-:mon' do
      year = params[:year].to_i
      mon = params[:mon].to_i
      fday = Date.new(year,mon,1)
      lday = fday.next_month
      month_day = (lday - fday).to_i
      before_day = fday.cwday % 7
      after_day = 7 - lday.cwday
      today = Date.today.day

      cbase = {}
      cbase[:where] = if @public_mode then {public:true} end
      cbase[:order] = [Sequel.asc(:start_at),Sequel.asc(:end_at)]

      (day_infos,items,events) = [
        [ScheduleDateInfo,:info,:make_info,Hash,{}],
        [ScheduleItem,:item,:make_item,Array,cbase],
        [Event,:event,:make_event,Array,cbase]
      ].map{|klass,sym,func,obj,cond|
        from = Date.new(year,mon,1)
        to = from.next_month
        query = klass.where{(date >= from) & (date < to)}
        if cond[:where] then
          query = query.where(cond[:where])
        end
        if cond[:order] then
          query = query.order(*cond[:order])
        end
        query.all.each_with_object(if obj == Array then Hash.new{[]} else {} end){|x,h|
          if obj == Array then
            h[x.date.day] <<= send(func,x)
          else
            h[x.date.day] = send(func,x)
          end
        }
      }
      {
        year: year,
        mon: mon,
        today: today,
        month_day: month_day,
        before_day: before_day,
        after_day: after_day,
        day_infos: day_infos,
        items: items,
        events: events
      }
    end
    SCHEDULE_EVENT_DONE_PER_PAGE = 40
    get '/ev_done',private:true do
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
