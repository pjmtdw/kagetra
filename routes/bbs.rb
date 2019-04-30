# -*- coding: utf-8 -*-
class MainApp < Sinatra::Base
  namespace '/api/bbs' do
    BBS_THREADS_PER_PAGE = 5
    get '/threads' do
      page = params['page'].to_i
      qs = params['qs']
      query = BbsThread.dataset
      if @public_mode
        query = query.where({ public: true })
      end
      if qs then
        query = query.right_join(BbsItem, thread_id: :id).qualify.distinct
        qs.strip.split(/\s+/).each{|q|
          qb = [
            :title,
            :bbs_items__body,
            :bbs_items__user_name
          ].map{|x|
            Sequel.like(x, "%#{q}%")
          }.inject(:|)
          query = query.where(qb)
        }
      end
      threads = query.paginate(page, BBS_THREADS_PER_PAGE).order(Sequel.desc(:last_comment_date),Sequel.desc(:bbs_threads__id)).map{|t|
        items = t.comments_dataset.order(Sequel.asc(:created_at)).map{|c| c.show(@user, @public_mode)}
        t.select_attr(:id, :title, :public).merge(items: items, has_new_comment: t.has_new_comment(@user))
      }
      return {
        count: query.count,
        threads_per_page: BBS_THREADS_PER_PAGE,
        threads: threads,
      }
    end
    get '/thread/:id' do
      id = params['id'].to_i
      thread = BbsThread.select(:id, :title, :public).where(id: id).first
      query = BbsThread.select(:id, :title)
      if @public_mode
        thread = nil unless thread.public
        query = query.where({ public: true })
      end
      if thread
        items = thread.comments_dataset.order(Sequel.asc(:created_at)).map{|c| c.show(@user, @public_mode)}
        thread = thread.select_attr(:id, :title, :public).merge(items: items, has_new_comment: thread.has_new_comment(@user))
      end
      prevThread = query.where{ self.id < id }.order(Sequel.desc(:id)).first
      nextThread = query.where{ self.id > id }.order(Sequel.asc(:id)).first
      return {
        thread: thread,
        prev: prevThread && prevThread.values,
        next: nextThread && nextThread.values,
      }
    end
    def create_item(thread,is_first)
      c = BbsItem.create(
        thread: thread,
        is_first: is_first,
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
      with_update{
        title = @json["title"]
        public = @public_mode || @json["public"]
        thread = BbsThread.create(title: title, public: public)
        create_item(thread,true)
      }
    end
    post '/item' do
      with_update{
        thread_id = @json["thread_id"]
        thread = BbsThread[thread_id.to_i]
        if @public_mode and not thread.public
          halt 403,"cannot write to private thread"
        end
        thread.touch # もう必要ないかも
        create_item(thread,false)
      }
    end
    put '/item/:id', auth: :user do
      with_update{
        item = BbsItem[params[:id].to_i]
        halt(403,"you cannot edit this item") unless item.editable(@user)
        item.update(body:@json["body"], user_name:@json["user_name"])
      }
    end
    delete '/item/:id', auth: :user do
      with_update{
        item = BbsItem[params[:id]]
        halt(403,"you cannot delete this item") unless item.editable(@user)
        thread = item.thread
        if item.is_first then
          thread.destroy
        else
          item.destroy
        end
      }
    end
  end
end
