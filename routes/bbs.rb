class MainApp < Sinatra::Base
  THREADS_PER_PAGE = 10
  namespace '/api/bbs' do
    get '/threads' do
      page = params["page"].to_i - 1
      qs = params["qs"]
      query = BbsThread.all(deleted: false)
      if qs then
        qs.strip.split(/\s+/).each{|q|
          # dummy query that never matches
          # TODO: more smarter way to create this ?
          qb = BbsThread.all(id: -1)
          [
            :title,
            BbsThread.bbs_item.user_name,
            BbsThread.bbs_item.body
          ].each{|sym|
            # TODO: escape query
            qb |= BbsThread.all(sym.like => "%#{q}%")
          }
          query &= qb
        }
      end
      query.all(order: [:updated_at.desc ]).chunks(THREADS_PER_PAGE)[page].map{|t|
        items = t.bbs_item(deleted: false).map{|i|
          {
            body: i.body,
            name: i.user_name,
            date: i.created_at.strftime("%Y-%m-%d %H:%M:%S")
          }
        }
        {thread_id: t.id, title: t.title, items: items}
      }
    end
    post '/new_thread' do
      user = get_user
      title = params["title"]
      body = params["body"]
      thread = BbsThread.create(title: title)
      item = BbsItem.create(body: body, bbs_thread: thread, user: user, user_name: user.name)
      thread.first_item = item
      thread.save
    end
    post '/response' do
      user = get_user
      body = params["body"]
      thread_id = params["thread_id"]
      thread = BbsThread.first(id: thread_id)
      thread.touch
      item = BbsItem.create(body: body, bbs_thread: thread, user: user, user_name: user.name)
    end
  end
  get '/bbs' do
    haml :bbs
  end
end
