class MainApp < Sinatra::Base
  register Sinatra::Namespace
  helpers Sinatra::ContentFor
  enable :sessions, :logging
  # ENV['RACK_SESSION_SECRET'] is set by unicorn.rb
  set :session_secret, 
    ((if defined?(CONF_SESSION_SECRET) then CONF_SESSION_SECRET end) or ENV["RACK_SESSION_SECRET"] or SecureRandom.base64(48)) 
  
  set :sessions, key:G_SESSION_COOKIE_NAME
  # for Internet Explorer 8, 9 (and maybe also 10?) protection session hijacking refuses the session.
  # https://github.com/rkh/rack-protection/issues/11
  set :protection, except: :session_hijacking

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

  configure :development do
    register Sinatra::Reloader

    get %r{/(.+)\.js$} do |m|
      content_type "application/javascript"
      js = if m.start_with?("foundation") then
        "#{Gem.loaded_specs['zurb-foundation'].full_gem_path}/js/foundation/#{m}.js"
      else
        "views/#{m}.js"
      end
      pass if not File.exist?(js) # pass to Rack::Coffee
      send_file(js)
    end

  end
  COMMENTS_PER_PAGE = 16
  def self.comment_routes(namespace,klass,klass_comment,private=false)
    get "#{namespace}/comment/list/:id",private:private do
      page = if params[:page] then params[:page].to_i else 1 end
      thread = klass.get(params[:id].to_i)
      chunks = thread.comments(order: [:created_at.desc,:id.desc]).chunks(COMMENTS_PER_PAGE)
      uidmap = {}
      list = chunks[page-1].map{|x|x.show(@user,@public_mode)}
      {
        thread_name: if thread.respond_to?(:name) then thread.name end,
        list: list,
        comment_count: thread.comment_count,
        has_new_comment: thread.has_new_comment(@user),
        cur_page: page,
        pages: chunks.size
      }
    end
    post "#{namespace}/comment/item",private:private do
      dm_response{
        evt = klass.get(@json["thread_id"].to_i)
        c = evt.comments.create(@json.select_attr("user_name","body").merge({user:@user}))
        c.set_env(request)
        c.save()
      }
    end
    put "#{namespace}/comment/item/:id" do
      dm_response{
        item = klass_comment.get(params[:id].to_i)
        halt(403,"you cannot edit this item") unless item.editable(@user)
        item.update(@json.select_attr("user_name","body"))
      }
    end
    delete "#{namespace}/comment/item/:id" do
      Kagetra::Utils.dm_debug{
        item = klass_comment.get(params[:id])
        halt(403,"you cannot delete this item") unless item.editable(@user)
        item.destroy()
      }
    end
  end
end
