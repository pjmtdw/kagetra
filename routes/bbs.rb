# -*- coding: utf-8 -*-
class MainApp < Sinatra::Base
  BBS_THREADS_PER_PAGE = 5
  namespace '/api/bbs' do
    get '/threads' do
      user = get_user
      page = params["page"].to_i - 1
      qs = params["qs"]
      query = BbsThread.all
      if qs then
        qs.strip.split(/\s+/).each{|q|
          # 一件もヒットしないダミーのクエリ
          # TODO: 以下をする正しい方法
          qb = BbsThread.all(id: -1)
          [
            :title,
            BbsThread.comments.user_name,
            BbsThread.comments.body
          ].each{|sym|
            # TODO: クエリのエスケープ
            qb |= BbsThread.all(sym.like => "%#{q}%")
          }
          query &= qb
        }
      end
      query.all(order: [:last_comment_date.desc ]).chunks(BBS_THREADS_PER_PAGE)[page].map{|t|
        items = t.comments.map{|i|
          i.select_attr(:id,:body,:user_name).merge(
          {
            date: i.created_at.strftime("%Y-%m-%d %H:%M:%S"),
            is_new: i.is_new(user)
          })
        }
        title = t.title
        {id: t.id, title: title, items: items, public: t.public}
      }
    end
    post '/thread' do
      dm_response{
        BbsItem.transaction{
          user = get_user
          title = @json["title"]
          body = @json["body"]
          public = @json["public"].to_s.empty?.!
          thread = BbsThread.create(title: title, public: public)
          item = thread.comments.create(body: body, user: user, user_name: user.name)
        }
      }
    end
    post '/item' do
      dm_response{
        BbsThread.transaction{
          user = get_user
          body = @json["body"]
          thread_id = @json["thread_id"]
          thread = BbsThread.get(thread_id.to_i)
          item = thread.comments.create(body: body, user: user, user_name: user.name)
          thread.touch
        }
      }
    end
    put '/item/:id' do
      dm_response{
        item = BbsItem.get(params[:id].to_i)
        item.update(body:@json["body"])
      }
    end
    delete '/item/:id' do
      Kagetra::Utils.dm_debug{
        BbsThread.transaction{
          item = BbsItem.get(params[:id])
          thread = item.thread
          if thread.first_item.id == item.id then
            # 関係するものを全部削除してからじゃないとダメ
            thread.comments.destroy
            thread.destroy
          else
            item.destroy
          end
        }
      }
    end
  end
  get '/bbs' do
    user = get_user
    haml :bbs,{locals: {user: user}}
  end
end
