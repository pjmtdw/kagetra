# -*- coding: utf-8 -*-
# 名簿
class MainApp < Sinatra::Base 
  ADDRBOOK_RECENT_MAX =50
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
        ab.select_attr(:text).merge({
          found:true,
          uid:uid,
          updated_date: ab.updated_at.strftime("%Y-%m-%d %H:%M")
        })
      end
      if @user.admin or @user.sub_admin or uid == @user.id then
        r[:editable] = true
      end
      r
    end
    # TODO: パスワードを平文で送るのは危険
    post '/change_pass',auth: :admin do
      cpass = @json["cur_password"]
      npass = @json["new_password"]
      Kagetra::Utils.single_exec{
        raise Exception.new("旧パスワードが違います") unless addrbook_check_password(cpass)

        AddrBook.transaction{
          AddrBook.all.each{|x|
            # 古いパスワードでデコードし，新しいパスワードでエンコードする
            plain = Kagetra::Utils.openssl_dec(x.text,cpass)
            # updated_atを更新しないように update! を使用する
            x.update!(text:Kagetra::Utils.openssl_enc(plain,npass))
          }
          Kagetra::Utils.set_addrbook_password(npass)
        }
      }
    end
    get '/recent' do
      recents = AddrBook.all(fields:[:user_id,:updated_at],order:[:updated_at.desc])[0...ADDRBOOK_RECENT_MAX].map{|x|
        next unless (x.user.nil?.! and x.updated_at)
        [x.user.id,x.updated_at.strftime("%Y-%m-%d")+": "+x.user.name]
      }.compact
      list = [[@user.id,"自分"]]
      {list:list+recents}
    end
  end
  get '/addrbook' do
    haml :addrbook
  end
end
