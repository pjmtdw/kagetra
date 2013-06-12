# -*- coding: utf-8 -*-


# copied from http://blog.tquadrado.com/2010/datamapper-update_or_create/
module DataMapper
  module Model
    # update_or_create method: finds and updates, or creates;
    #   -upon create, returns the object
    #   -upon update, returns the object (by default, returned True)
    # @param[Hash] Conditions hash for the search query.
    # @param[Hash] Attributes hash with the property value for the update or creation of a new row.
    # @param[Boolean] Merger is a boolean that determines if the conditions are merged with the attributes upon create.
    #   If true, merges conditions to attributes and passes the merge to the create method;
    #   If false, only attributes are passed into the create method
    # @return[Object] DataMapper object 
    def update_or_create(conditions = {}, attributes = {}, merger = true)
      begin
	if (row = first(conditions))
          row.update(attributes)
	  row
	else
	  create(merger ? (conditions.merge(attributes)) : attributes )
	end
      rescue
        false
      end
    end
  end # Module Model
end # Module DataMapper

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

    def self.gen_salt
      SecureRandom.base64(24)
    end
    def self.hash_password(pass,salt=nil)
      salt ||= gen_salt
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
    def self.escape_html_br(s)
      Rack::Utils.escape_html(s).gsub("\n","<br>")
    end

    def self.zenkaku_to_hankaku(s)
      NKF::nkf('-wZ0',s)
    end

    def self.kansuuji_to_arabic(s)
      buf = s.clone
      "一二三四五六七八九".scan(".").each_with_index{|x,i|
        buf.gsub!(x,(i+1).to_s)
      }
      buf
    end

    def self.normalize_token(s)
      self.zenkaku_to_hankaku(s).gsub(/\s+/,"")
    end
    def self.eval_score_char(s)
      return if s.nil?
      s = self.normalize_token(s)
      if /^(\d|\+|\-)+$/ =~ s then
        begin
          eval(s)
        rescue
        end
      end
    end
    def self.class_from_name(s)
      return if s.nil?
      s = self.normalize_token(s)
      if /^[a-hA-H]/ =~ s
        $&.downcase.to_sym
      else
        nil
      end
    end
    def self.rank_from_prize(prize)
      return if prize.nil?
      prize = self.normalize_token(prize)
      prize = self.kansuuji_to_arabic(prize)
      case prize
      when "優勝" then 1
      when "準優勝" then 2
      when /^(\d+)位$/ then $1.to_i
      end
    end
  end
end
