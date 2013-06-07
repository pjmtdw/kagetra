class MainApp < Sinatra::Base
  EVENTS_PER_PAGE = 4
  HALF_PAGE = EVENTS_PER_PAGE/2
  namespace '/api/result' do
    get '/contest/:id' do
      cond = Event.all(kind: :contest, :date.lte => Date.today)
      evt = (cond & Event.all(
              if params[:id] == "latest" then
                {order: [:date.desc]}
              else
                {id: params[:id].to_i}
              end
            )).first
      (pre,post) = [[:lt,:desc],[:gt,:asc]].map{|p,q|
        (cond & (Event.all(date:evt.date, :id.send(p) => evt.id) | Event.all(:date.send(p) => evt.date)))
        .all(order: [:date.send(q), :id.send(q)])[0...EVENTS_PER_PAGE]
      }
      # execute query and obtain list
      pre = pre.to_a
      post = post.to_a
      all = if pre.size <= HALF_PAGE then
        p "a"
        (pre + [evt] + post)[0..EVENTS_PER_PAGE].reverse
      elsif post.size <= HALF_PAGE then
        p "b"
        (post.reverse + [evt] + pre)[0..EVENTS_PER_PAGE]
      else
        (pre[0...HALF_PAGE].reverse + [evt] + post[0...HALF_PAGE]).reverse
      end

      list = all.map{|x| x.select_attr(:id,:name)}
      group = evt.event_group.events(order:[:date.desc]).map{|x| x.select_attr(:id,:name,:date)}
      evt.select_attr(:id,:name,:num_teams,:date).merge({
        list: list,
        group: group
      })
    end

  end
  get '/result' do
    user = get_user
    haml :result, locals:{user: user}
  end
end
