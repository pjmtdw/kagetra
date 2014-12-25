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
    # in production environment, we use nginx's rewrite module for following url conversion
    register Sinatra::Reloader
    get %r{/js/v\d+/libs/(.+)} do |m|
      send_file("views/js/libs/#{m}")
    end

    get %r{/js/v\d+/(.+)\.js$} do |m|
      # Sends /views/js/*.js if available, otherwise compile /views/js/*.coffee
      # if you updated /views/js/*.coffee, you have to delete /views/js/*.js to reflect the change
      content_type "application/javascript"
      js = if m.start_with?("foundation") then
        # used for debugging from gem
        "#{Gem.loaded_specs['zurb-foundation'].full_gem_path}/js/foundation/#{m}.js"
      else
        "views/js/#{m}.js"
      end
      redirect "/js/#{m}.js" if not File.exist?(js) # pass to Rack::Coffee
      send_file(js)
    end

    get %r{/css/v\d+/(.+)\.css$} do |m|
      redirect "/css/#{m}.css" # pass to Sass::Plugin::Rack
    end

  end
  COMMENTS_PER_PAGE = 16
  def self.comment_routes(namespace,klass,klass_comment,private=false)
    get "#{namespace}/comment/list/:id",private:private do
      page = if params[:page] then params[:page].to_i else 1 end
      thread = klass[params[:id].to_i]
      return [] if thread.nil?
      chunks = thread.comments_dataset.order(Sequel.desc(:created_at),Sequel.desc(:id)).paginate(page,COMMENTS_PER_PAGE)
      uidmap = {}
      
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
end
