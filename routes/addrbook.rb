# -*- coding: utf-8 -*-
# 名簿
class MainApp < Sinatra::Base 
  namespace '/api/addrbook' do
    post '/item/:uid' do
      AddrBook.update_or_create({user_id:params[:uid]},{text:@json["text"]})
    end
    get '/item/:uid' do
      uid = params[:uid].to_i
      ab = AddrBook.first(user_id:uid)
      r = if ab.nil? then
        u2 = if uid == @user.id then @user else User.get(uid) end
        {
          found:false,
          uid: u2.id,
          default:
          {
            "名前" => u2.name,
            "ふりがな" => u2.furigana,
          }
        }
      else
        ab.select_attr(:text).merge({found:true,uid:uid})
      end
      if uid == @user.id then
        r[:editable] = true
      end
      r
    end
  end
  get '/addrbook' do
    # パスワードが正しいかどうかの確認用
    confirm_enc = MyConf.first(name: "addrbook_confirm_enc").value["text"]
    haml :addrbook,{locals: {confirm_enc: confirm_enc}}
  end
end
