# -*- coding: utf-8 -*-
module Kagetra
  class HourMin
    def initialize(hour,min)
      @hour = hour.to_i
      @min = min.to_i
    end
    def self.parse(str)
      if /^(\d\d):(\d\d)$/ =~ str then
        HourMin.new($1,$2)
      else
        raise Exception.new("invalid HourMin: '#{str}'")
      end
    end
    def to_s
      "%02d:%02d" % [ @hour, @min ]
    end
  end
  module Utils
    # in UNICODE order
    GOJUON_ROWS = [
      {name: "あ行", range: ["ぁ", "お"]},
      {name: "か行", range: ["か", "ご"]},
      {name: "さ行", range: ["さ", "ぞ"]},
      {name: "た行", range: ["た", "ど"]},
      {name: "な行", range: ["な", "の"]},
      {name: "は行", range: ["は", "ぽ"]},
      {name: "ま行", range: ["ま", "も"]},
      {name: "や行", range: ["ゃ", "よ"]},
      {name: "ら行", range: ["ら", "ろ"]},
      {name: "わ行", range: ["ゎ", "ん"]}
    ]
    def self.dm_debug
      begin
        yield
      rescue DataMapper::SaveFailureError => e
        p e.resource.errors
        raise e
      end
    end
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
    def self.hash_password(pass,salt=nil)
      salt ||= SecureRandom.base64(24)
      # Iteration must be at least 1,000 for secure pbkdf2.
      # However, CryptoJS is too slow for executing 1,000 iterations on browser.
      {
       hash: Base64.encode64(OpenSSL::PKCS5.pbkdf2_hmac_sha1(pass,salt,100,32)).gsub("\n",""),
       salt: salt
      }
    end
    def self.hmac_password(hash,msg)
      Base64.encode64(OpenSSL::HMAC.digest(OpenSSL::Digest::Digest.new('sha256'), hash, msg)).gsub("\n","")
    end
    def self.zenkaku_to_hankaku(s)
      NKF::nkf('-wZ0',s)
    end
    def self.eval_score_char(s)
      s = self.zenkaku_to_hankaku(s).gsub(/\s+/,"")
      if /^(\d|\+|\-)+$/ =~ s then
        begin
          eval(s)
        rescue
        end
      end
    end
  end
end
