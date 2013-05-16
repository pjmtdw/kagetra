# -*- coding: utf-8 -*-
module Kagetra
  # in UNICODE order
  GOJUON_ROWS = [
    {:name=>"あ行", :range=>["ぁ", "お"]},
    {:name=>"か行", :range=>["か", "ご"]},
    {:name=>"さ行", :range=>["さ", "ぞ"]},
    {:name=>"た行", :range=>["た", "ど"]},
    {:name=>"な行", :range=>["な", "の"]},
    {:name=>"は行", :range=>["は", "ぽ"]},
    {:name=>"ま行", :range=>["ま", "も"]},
    {:name=>"や行", :range=>["ゃ", "よ"]},
    {:name=>"ら行", :range=>["ら", "ろ"]},
    {:name=>"わ行", :range=>["ゎ", "ん"]}
  ]
  def self.unicode_first(s)
    s[0].unpack("U*")[0]
  end
  def self.gojuon_row_num(s)
    c = unicode_first(s)
    GOJUON_ROWS.find_index{|x|
      (l,r) = x[:range].map{|y|
        unicode_first(y)
      }
      l <= c and c <= r
    } or -1
  end
  def self.gojuon_row_names
    GOJUON_ROWS.map{|x|
      x[:name]
    }
  end
end
