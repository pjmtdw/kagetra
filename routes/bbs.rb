class MainApp < Sinatra::Base
  THREADS_PER_PAGE = 10
  namespace '/api/bbs' do
    get '/threads' do
      page = params["page"].to_i - 1
      BbsThread.chunks(THREADS_PER_PAGE)[page].map{|t|
        items = t.bbs_item.map{|i|
          {
            body: i.body,
            name: i.user_name
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
