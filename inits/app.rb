class MainApp < Sinatra::Base
  register Sinatra::Namespace
  helpers Sinatra::ContentFor
  enable :sessions, :logging
  # ENV['RACK_SESSION_SECRET'] is set by unicorn.rb
  set :root, File.join(File.dirname(__FILE__),"..")
  set :session_secret,
    ((if CONF_SESSION_SECRET.to_s.empty?.! then CONF_SESSION_SECRET end) or ENV["RACK_SESSION_SECRET"] or SecureRandom.base64(48))

  set :sessions, key:G_SESSION_COOKIE_NAME
  # for Internet Explorer 8, 9 (and maybe also 10?) session_hijacking protection refuses the session.
  # https://github.com/rkh/rack-protection/issues/11
  # disable frame_options protection to allow <iframe>
  set :protection, except: [:session_hijacking,:frame_options]


  def logger
    env['mainapp.logger'] || env['rack.logger']
  end

  # using `set :show_exceptions, :after_handler` can only catch classes under Exception, not under Error
  # so we do the following hack
  disable :show_exceptions # disable Sinatra ShowExceptions
  set :raise_errors, settings.development? # enable fallback to Rack::ShowExceptions
  error do
    err = request.env['sinatra.error']
    logger.warn err.message
    logger.puts err.backtrace.join("\t\n")
  end

  set(:auth) do |*roles|
    condition do
      if roles.any?{|role| role == :admin } and not @user.admin
        halt 403
      end
    end
  end


  configure :development do
    register Sinatra::Reloader
  end
  COMMENTS_PER_PAGE = 16
  def self.comment_routes(namespace,klass,klass_comment,private=false)
    get "#{namespace}/comment/list/:id",private:private do
      page = if params[:page] then params[:page].to_i else 1 end
      thread = klass[params[:id].to_i]
      return [] if thread.nil?
      chunks = thread.comments_dataset.order(Sequel.desc(:created_at),Sequel.desc(:id)).paginate(page,COMMENTS_PER_PAGE)
      tsym = [:name,:title].find{|s|thread.respond_to?(s)}
      tname = tsym && thread.send(tsym)

      list = chunks.map{|x|x.show(@user,@public_mode)}
      {
        thread_name: tname,
        list: list,
        comment_count: thread.comment_count,
        has_new_comment: thread.has_new_comment(@user),
        cur_page: page,
        pages: chunks.page_count
      }
    end
    post "#{namespace}/comment/item",private:private do
      with_update{
        evt = klass[@json["thread_id"].to_i]
        c = klass_comment.create(@json.select_attr("user_name","body").merge({user:@user,thread:evt}))
        c.set_env(request)
        c.save()
      }
      []
    end
    put "#{namespace}/comment/item/:id" do
      with_update{
        item = klass_comment[params[:id].to_i]
        halt(403,"you cannot edit this item") unless item.editable(@user)
        item.update(@json.select_attr("user_name","body"))
      }
    end
    delete "#{namespace}/comment/item/:id" do
      with_update{
        item = klass_comment[params[:id]]
        halt(403,"you cannot delete this item") unless item.editable(@user)
        item.destroy()
      }
    end
  end
  ATTACHED_LIST_PER_PAGE = 50
  def self.attached_routes(namespace,klass,klass_attached)
    get "/api/#{namespace}/attached_list/:id" do
      page = (params[:page] || 1).to_i
      chunks = klass_attached.where(thread_id:params[:id].to_i).order(Sequel.desc(:created_at),Sequel.desc(:id)).paginate(page,ATTACHED_LIST_PER_PAGE)
      pages = chunks.page_count
      list = chunks.map{|x|
        x.select_attr(:id,:orig_name,:description,:size).merge({
          date:x.created_at.to_date.strftime('%Y-%m-%d'),
          editable: @user.admin || x.owner_id == @user.id
        })
      }
      {item_id:params[:id].to_i,list: list, pages: pages, cur_page: page}
    end
    delete "/api/#{namespace}/attached/:id", private:true do
      klass_attached[params[:id].to_i].destroy
    end
    get "/static/#{namespace}/attached/:id/:filename" do
      # content-dispositionでutf8を使う方法は各ブラウザで統一されていないので
      # :filenameの部分にダウンロードさせるファイル名を入れるという古くから使える方法を取る
      attached_base = File.join(CONF_STORAGE_DIR,"attached",namespace)
      attached = klass_attached[params[:id].to_i]
      halt 404 if attached.nil?
      send_file(File.join(attached_base,attached.path),disposition:nil)
    end
    # ajaxを使うように変更したので↓は不要
    # 返信を Content-Type: text/html で返す必要があるので /api/ の route には置かない
    post "/api/#{namespace}/attached/:id", private:true do
      item = klass[params[:id].to_i]
      attached =  if params[:attached_id] then
                    item.attacheds_dataset.first(id:params[:attached_id])
                  end
      attached_base = File.join(CONF_STORAGE_DIR,"attached",namespace)
      file =  if params[:file] then
                params[:file]
              else
                {
                  tempfile: nil,
                  filename: params[:orig_name]
                }
              end
      tempfile = file[:tempfile]
      filename = file[:filename]
      target_file =
        if attached then
          File.join(attached_base,attached.path)
        else
          date = Date.today
          target_dir = File.join(attached_base,date.year.to_s,date.month.to_s)
          FileUtils.mkdir_p(target_dir)
          Kagetra::Utils.unique_file(@user,["attached-",".dat"],target_dir)
        end
      res = begin
        DB.transaction{
          FileUtils.cp(tempfile.path,target_file) if tempfile
          if attached then
            base = params.select_attr("description")
            base[:orig_name] = filename
            if tempfile then
              base[:size] = File.size(tempfile)
            end
            attached.update(base)
          else
            rel_path = Pathname.new(target_file).relative_path_from(Pathname.new(attached_base))
            klass_attached.create(thread_id:item.id,owner:@user,path:rel_path,orig_name:filename,description:params[:description],size:File.size(target_file))
          end
        }
        {result:"OK"}
      rescue Exception=>e
        logger.warn e.message
        $stderr.puts e.message
        FileUtils.rm(target_file,force:true) unless attached
        error_response('送信失敗')
      end
      res
    end
  end
end
