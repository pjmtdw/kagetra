class MainApp < Sinatra::Base
  THREADS_PER_PAGE = 10
  namespace '/api/bbs' do
    get '/threads' do
      page = params["page"].to_i - 1
      BbsThread.all(deleted: false, order: [:created_at.desc ]).chunks(THREADS_PER_PAGE)[page].map{|t|
        items = t.bbs_item(deleted: false).map{|i|
          {
            body: i.body,
            name: i.user_name,
            date: i.created_at.strftime("%Y-%m-%d %H:%M:%S")
          }
        }
        {title: t.title, items: items}
      }
    end
  end
  get '/bbs' do
    haml :bbs
  end
end
