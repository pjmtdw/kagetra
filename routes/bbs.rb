# -*- coding: utf-8 -*-
class MainApp < Sinatra::Base
  BBS_THREADS_PER_PAGE = 5
  namespace '/api/bbs' do
    get '/threads' do
      page = params["page"].to_i
      qs = params["qs"]
      cond = if @public_mode then {public:true} else {} end
      query = BbsThread.where(cond)
      if qs then
        query = query.right_join(BbsItem,thread_id: :id).qualify.distinct
        qs.strip.split(/\s+/).each{|q|
          qb = [
            :title,
            :bbs_items__body,
            :bbs_items__user_name
          ].map{|x|
            # TODO: escape query
            Sequel.like(x,"%#{q}%")
          }.inject(:|)
          query = query.where(qb)
        }
      end
      query.paginate(page,BBS_THREADS_PER_PAGE).order(Sequel.desc(:last_comment_date),Sequel.desc(:bbs_threads__id)).map{|t|
        items = t.comments.map{|c|c.show(@user,@public_mode)}
        t.select_attr(:id,:title,:public).merge(items:items,has_new_comment:t.has_new_comment(@user))
      }
    end
    def create_item(thread)
      c = thread.comments.create(
        body: @json["body"],
        user: @user,
        user_name: @json["user_name"])
      c.set_env(request)
      c.save()
      if @public_mode then
        set_permanent("bbs_name",@json["user_name"])
      end
    end
    post '/thread' do
      dm_response{
        BbsItem.transaction{
          title = @json["title"]
          public = @public_mode || @json["public"]
          thread = BbsThread.create(title: title, public: public)
          create_item(thread)
        }
      }
    end
    post '/item' do
      dm_response{
        BbsThread.transaction{
          thread_id = @json["thread_id"]
          thread = BbsThread.get(thread_id.to_i)
          if @public_mode and not thread.public
            halt 403,"cannot write to private thread"
          end
          thread.touch # もう必要ないかも
          create_item(thread)
        }
      }
    end
    put '/item/:id' do
      dm_response{
        item = BbsItem.get(params[:id].to_i)
        halt(403,"you cannot edit this item") unless item.editable(@user)
        item.update(body:@json["body"])
      }
    end
    delete '/item/:id' do
      Kagetra::Utils.dm_debug{
        item = BbsItem.get(params[:id])
        halt(403,"you cannot delete this item") unless item.editable(@user)
        BbsThread.transaction{
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
    haml :bbs
  end
end
