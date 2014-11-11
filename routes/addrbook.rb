# -*- coding: utf-8 -*-
# 名簿
class MainApp < Sinatra::Base
  ADDRBOOK_RECENT_MAX =50
  def make_addrbook_info(ab)
    album_item = ab.album_item && ab.album_item.id_with_thumb
    ab.select_attr(:text).merge({
      album_item:album_item,
      found:true,
      uid: ab.user_id,
      updated_date: ab.updated_at.strftime("%Y-%m-%d %H:%M"),
    })
  end
  namespace '/api/addrbook' do
    post '/item/:uid' do
      ab = AddrBook.update_or_create({user_id:params[:uid]},{text:@json["text"],album_item_id:@json["album_item_id"]})
      make_addrbook_info(ab)
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
        make_addrbook_info(ab)
      end
      if @user.admin or @user.sub_admin or uid == @user.id then
        r[:editable] = true
      end

      r[:user_attrs] = UserAttributeValue
        .graph(UserAttributeKey, id: :attr_key_id)
        .where(user_attribute: UserAttribute.where(user_id: uid))
        .where{user_attribute_keys__index > 0}
        .order(:user_attribute_keys__index)
        .map{|x|
          [x[:user_attribute_keys].name,x[:user_attribute_values].value]
        }
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
      recents = AddrBook.order(Sequel.desc(:addr_books__updated_at))
        .where(Sequel.~({addr_books__updated_at:nil}))
        .limit(ADDRBOOK_RECENT_MAX).graph(User, id: :user_id)
        .map{|x|
          ab = x[:addr_books]
          u = x[:users]
          [ab.user_id,ab.updated_at.strftime("%Y-%m-%d")+": "+u.name]
        }
      list = [[@user.id,"自分"]]
      {list:list+recents}
    end
  end
  get '/addrbook' do
    haml :addrbook
  end
end
