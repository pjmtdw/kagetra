#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# 体験版として公開できるように個人情報に繋りそうな要素を削除/置換する
# 使い方: 一つ上のフォルダで bundle exec scripts/anonymize.rb

# $ apt-get install ruby-mecab mecab-ipadic-utf8
require "MeCab"
require_relative '../inits/init'
require_relative './wikipedia_name/random.rb'

CONF_MEIBO_PASSWORD = "XXXX" # セキュリティのため使用した後は元に戻すこと

# 写真をぼかす
AlbumGroup.all.each{|ag|
  ag.items.each{|item|
    [item.thumb,item.photo].each{|x|
      old_path = x.path
      next if old_path.to_s.end_with?(".blurred")
      new_path = old_path.to_s+".blurred"
      abs_path = File.join(G_STORAGE_DIR,"album",old_path)
      x.update!(path:new_path)
      new_abs_path = File.join(G_STORAGE_DIR,"album",new_path)
      next if File.exist?(new_abs_path)
      if File.exist?(abs_path) and File.size(abs_path) > 0
        image = Magick::Image.read(abs_path).first
        size = [x.width,x.height].max
        image = image.blur_image(size/30.0,size/50.0)
        puts "writing to: #{new_path}"
        image.write(new_abs_path)
      else
        puts "WARNING: skip #{abs_path} since it does not exist or size is zero"
      end
      }}
}
# 大会結果をシャッフル
DB.transaction{
  EventGroup.all.each{|gr|
    events = gr.events_dataset.where{ date <= Date.today }
    next if events.count <= 1
    old_ids = events.map{|x|x.id}
    new_ids = old_ids.shuffle
    # 重複IDは許されないので存在しないIDに変更しておく
    id_max = Event.max(:id)+1
    temp_ids = []
    old_ids.each_with_index{|id,i|
      t = id_max + i
      ContestUser.where(event_id:id).each{|x|x.update!(event_id:t)}
      ContestClass.where(event_id:id).each{|x|x.update!(event_id:t)}
      temp_ids << t
    }
    temp_ids.each_with_index{|t,i|
      ContestUser.where(event_id:t).each{|x|x.update!(event_id:new_ids[i])}
      ContestClass.where(event_id:t).each{|x|x.update!(event_id:new_ids[i])}
    }
  }
}
# ユーザ名をランダムなものに変更
DB.transaction{
  namemap = {}
  User.all.each{|u|
    c = RandomName.choose
    namemap[u.name] = c[:name]
    u.update(name:c[:name],furigana:c[:furigana])
  }
  [
    [BbsItem,:user_name],
    [EventComment,:user_name],
    [EventUserChoice,:user_name],
    [ContestUser,:name],
    [ContestGame,:opponent_name],
    [AlbumTag,:name]
  ].each{|klass,sym|
    klass.all.each{|item|
      u = if item.respond_to?(:user) then item.user end
      un = item.send(sym)
      next if un.nil?
      nn =  if u.nil?.! then
              u.name
            elsif namemap.has_key?(un)
              namemap[un]
            else
              c = RandomName.choose
              namemap[un] = c[:name]
              c[:name]
            end
      item.update!(sym => nn)
    }
  }
}
# 掲示板や大会行事コメントなどの中の固有名詞とメールアドレスと電話番号を置換
# TODO: NKFで一々utf-8に変換するのは遅い(?)．元々がutf-8って分かっているので内部encodingをascii8bit->utf-8に変えるだけでいい
DB.transaction{
  mecab = MeCab::Tagger.new("")
  namemap = {}
  [
    [AddrBook,[:text]],
    [Event,[:description,:place,:name,:formal_name]],
    [ScheduleItem,[:name,:description,:place]],
    [EventComment,[:body]],
    [BbsThread,[:title]],
    [BbsItem,[:body]],
    [AlbumItem,[:name,:place,:comment,:tag_names]],
    [AlbumGroup,[:name,:place,:comment]],
    [WikiAttachedFile,[:orig_name,:description]],
    [WikiItem,[:title,:body]],
    [ContestTeam,[:name]],
    [ContestTeamOpponent,[:name]],
    [ContestGame,[:opponent_belongs]]
  ].each{|klass,syms|
    klass.all.each{|item|
      updates = syms.each_with_object({}){|sym,res|
        text = item.send(sym)
        next if text.to_s.empty?
        if klass == AddrBook and sym == :text then
          text = NKF.nkf("-w",Kagetra::Utils.openssl_dec(text,CONF_MEIBO_PASSWD))
        end
        reps = text.lines.map{|line|
          line.gsub!(Kagetra::Utils::EMAIL_ADDRESS_REGEX,"***@***.***")
          line.gsub!(Kagetra::Utils::TELEPHONE_NUMBER_REGEX,"**-****-****")
          n = mecab.parseToNode(line.chomp)
          buf = ""
          # 有効なfeature一覧は ipadic/pos-id.def に書いてある
          while n do
            feature = NKF.nkf("-w",n.feature)
            surface = NKF.nkf("-w",n.surface)
            # 京都大会ABCなどのABCが固有名詞として判断されてしまうためABCの部分は変換しない
            s = if /^(\w|[Ａ-Ｚａ-ｚ]){,4}$/i !~ surface and feature.start_with?("名詞,固有名詞")
              if namemap.has_key?(surface) then
                namemap[surface]
              else
                rest = feature.sub(/^名詞,固有名詞,/,"")
                meisi = case rest
                when "人名,名" then
                  RandomName.choose_mei
                else
                  # TODO: 組織と地域には人名とは別のデータを使う
                  # 郵便局のページから全国一括ダウンロードできる郵便番号データが候補
                  # http://www.post.japanpost.jp/zipcode/dl/oogaki/zip/ken_all.zip
                  RandomName.choose_sei
                end
                namemap[surface] = meisi
                meisi
              end
            else
              surface
            end
            buf += s
            n = n.next
          end
          buf
        }
        new_text = reps.join("\n")
        if klass == AddrBook and sym == :text then
          data = JSON.parse(new_text)
          data.delete("所属")
          data.delete("出身高校")
          data.delete("郵便番号1")
          data.delete("郵便番号2")
          data["名前"] = item.user.name
          data["ふりがな"] = item.user.furigana
          new_text = Kagetra::Utils.openssl_enc(data.to_json,CONF_MEIBO_PASSWD)
        end
        res[sym] = new_text
      }
      item.update!(updates)
    }
  }
}
