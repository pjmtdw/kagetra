class MainApp < Sinatra::Base
  THREADS_PER_PAGE = 10
  namespace '/api/bbs' do
    get '/threads' do
      page = params["page"].to_i - 1
      qs = params["qs"]
      query = BbsThread.all
      if qs then
        qs.strip.split(/\s+/).each{|q|
          # dummy query that never matches
          # TODO: more smarter way to create this ?
          qb = BbsThread.all(id: -1)
          [
            :title,
            BbsThread.items.user_name,
            BbsThread.items.body
          ].each{|sym|
            # TODO: escape query
            qb |= BbsThread.all(sym.like => "%#{q}%")
          }
          query &= qb
        }
      end
      query.all(order: [:updated_at.desc ]).chunks(THREADS_PER_PAGE)[page].map{|t|
        items = t.items.map{|i|
          body = Rack::Utils.escape_html(i.body).gsub("\n","<br>")
          {
            body: body,
            name: i.user_name,
            date: i.created_at.strftime("%Y-%m-%d %H:%M:%S")
          }
        }
        title = Rack::Utils.escape_html(t.title)
        {thread_id: t.id, title: title, items: items}
      }
    end
    post '/thread/new' do
      BbsItem.transaction{
        user = get_user
        title = params["title"]
        body = params["body"]
        thread = BbsThread.create(title: title)
        item = thread.items.create(body: body, user: user, user_name: user.name)
        thread.first_item = item
        thread.save
      }
    end
    post '/response/new' do
      user = get_user
      body = params["body"]
      thread_id = params["thread_id"]
      thread = BbsThread.first(id: thread_id)
      thread.touch
      item = thread.items.create(body: body, user: user, user_name: user.name)
    end
  end
  get '/bbs' do
    user = get_user
    haml :bbs,{locals: {user: user}}
  end
end
