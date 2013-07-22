
class MainApp < Sinatra::Base
  namespace '/api/user_conf' do
    get '/etc' do
      {bbs_public_name:@user.bbs_public_name}
    end
    post '/etc' do
      @user.update(bbs_public_name:@json["bbs_public_name"])
    end
  end
  get '/user_conf' do
    attr_keys = UserAttributeKey.all(order:[:index.asc])
    @user_attrs = @user.attrs.map{|x|k=x.value.attr_key;[k.index,k.name,x.value.value]}.sort_by{|i,n,v|i}
    haml :user_conf
  end
end
