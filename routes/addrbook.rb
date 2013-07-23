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
    # TODO: パスワードを平文で送るのは危険
    post '/change_pass' do
      cpass = @json["cur_password"]
      npass = @json["new_password"]
      Kagetra::Utils.single_exec{
        raise Exception.new("旧パスワードが違います") unless addrbook_check_password(cpass)

        AddrBook.transaction{
          AddrBook.all.each{|x|
            # 古いパスワードでデコードし，新しいパスワードでエンコードする
            plain = Kagetra::Utils.openssl_dec(x.text,cpass)
            x.update(text:Kagetra::Utils.openssl_enc(plain,npass))
          }
          Kagetra::Utils.set_addrbook_password(npass)
        }
      }
    end
  end
  get '/addrbook' do
    haml :addrbook
  end
end
