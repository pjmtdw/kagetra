class MainApp < Sinatra::Base
  enable :sessions
  get '/user/initials' do
    content_type :json
    User.all.map{|x|x.furigana[0]}.uniq.sort.map{|x|
      [x.unpack("U*")[0],x]
    }.to_json
  end
  get '/user/list/:initial' do
    content_type :json
    word = [params[:initial].to_i].pack("U*")
    User.all(:order => [:furigana.asc], :furigana.like => "#{word}%").map{|x|
      [x.id,x.name]
    }.to_json

  end
  get '/' do
    if not session.has_key?(:count) then
      session[:count] = 0
    else
      session[:count] += 1
    end
    count = session[:count]
    haml :index, :locals => {:count => count, :page_title => "counter"}
  end
end
