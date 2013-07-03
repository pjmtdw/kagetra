#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# Wikipedia日本語版の概要から人名っぽい部分を抽出する．
#  "佐藤 太郎（さとう たろう" のような部分を正規表現で取り出す．
#  人名漢字と常用漢字以外のものは除外．
#  戦国時代の武将やアニメのキャラなど現在の日本の名前とはかけ離れた名前も多い．
# 使い方: 
#   (1) http://dumps.wikimedia.org/jawiki/ から jawiki-YYYYMMDD-abstract.xml をダウンロード．
#   (2) $ ./extract_names.rb < jawiki-YYYYMMDD-abstract.xml
# tmpフォルダに出力されるファイル:
#   sei_1.txt, sei_2.txt, sei_3.txt ... 1文字,2文字,3文字の姓
#   mei_1.txt, wei_2.txt, mei_3.txt ... 1文字,2文字,3文字の名
# 出力されるファイルの形式:
#   "漢字\tふりがな\n"

require "set"

# 日本の1文字姓上位200
ONE_SEI = File.readlines("one_sei.txt").join("").chomp
# 日本の常用漢字一覧
JOYO_KANJI = File.readlines("joyo_kanji.txt").join("").chomp
# 日本の人名用漢字一覧
JINMEI_KANJI = File.readlines("jinmei_kanji.txt").join("").chomp

r = {
  sei:Array.new(3){Set.new},
  mei:Array.new(3){Set.new}
}

def is_jinmei(s)
  ss = s.gsub(/\p{Hiragana}+/,"")
  return true if ss.empty?
  ss.scan(/./).all?{|x|
    JOYO_KANJI.include?(x) or JINMEI_KANJI.include?(x)
  }
end

$<.each{|line|
  line.chomp!
  next unless /^<abstract>(\p{Han}{1,3})\s+((\p{Han}|\p{Hiragana}){1,3})\s*[（|(](\p{Hiragana}{2,})\s+(\p{Hiragana}{2,})/u =~ line
  (sei,mei,_,sei_f,mei_f) = $~.to_a[1..-1]
  next if sei.size == 1 and not ONE_SEI.include?(sei) # 1文字の場合は上位200以内の姓以外は除外
  next unless is_jinmei(sei) and is_jinmei(mei)
  r[:sei][sei.size-1].add("#{sei}\t#{sei_f}")
  r[:mei][mei.size-1].add("#{mei}\t#{mei_f}")
}
FileUtils.mkdir("tmp")
r.each{|k,v|
  v.each_with_index{|a,i|
    File.open("tmp/#{k}_#{i+1}.txt","w"){|f|
      f.puts(a.to_a.sort.join("\n"))
    }
  }
}
