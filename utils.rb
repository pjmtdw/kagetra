# -*- coding: utf-8 -*-

class Hash
  # {a:1,b:2,c:3}.select_attr(:a,:c) =>{a:1,c:3}
  def select_attr(*symbols)
    Hash[symbols.map{|s|[s,self[s]]}]
  end
end

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
    # Equivalent to:
    #   CryptoJS.AES.encrypt(plain_text, "Secret Passphrase")
    #   $ openssl enc -e -base64 -aes-256-cbc -in infile -out outfile -pass pass:"Secret Passphrase"
    def self.openssl_enc(plain, passphrase)
      salt = SecureRandom.random_bytes(8)
      aes = OpenSSL::Cipher::Cipher.new('AES-256-CBC').encrypt
      aes.pkcs5_keyivgen(passphrase, salt, 1)
      encrypted = aes.update(plain) + aes.final
      Base64.strict_encode64("Salted__"+salt+encrypted)
    end

    # Equivalent to:
    #   CryptoJS.AES.decrypt(encrypted_text, "Secret Passphrase")
    #   $ openssl enc -d -base64 -aes-256-cbc -in infile -out outfile -pass pass:"Secret Passphrase"
    def self.openssl_dec(encrypted, passphrase)
      cryptArr = Base64.strict_decode64(encrypted)
      magic = cryptArr[0..7] # must be "Salted__" but will ignore here
      salt  = cryptArr[8..15]
      data  = cryptArr[16..-1] 
      aes = OpenSSL::Cipher::Cipher.new('AES-256-CBC').decrypt
      aes.pkcs5_keyivgen(passphrase, salt, 1)
      aes.update(data) + aes.final
    end

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
    def self.dm_debug(arg=nil)
      begin
        yield
      rescue DataMapper::SaveFailureError => e
        puts "#{e.resource.errors.inspect} #{if arg then 'at '+arg end}"
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
       hash: Base64.strict_encode64(OpenSSL::PKCS5.pbkdf2_hmac_sha1(pass,salt,100,32)),
       salt: salt
      }
    end
    def self.hmac_password(hash,msg)
      Base64.strict_encode64(OpenSSL::HMAC.digest(OpenSSL::Digest::Digest.new('sha256'), hash, msg))
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

    # ブロック部分を実行できるのは一プロセスのみ．ロックしている間他のプロセスは素通りする
    # 全然関係ないプロセスが $0 を flock することはないことが前提
    def self.single_exec
      File.open($0){|f|
        return unless f.flock(File::LOCK_EX | File::LOCK_NB)
        begin
          yield
        ensure
          f.flock(File::LOCK_UN | File::LOCK_NB)
        end
      }
    end

    EMAIL_ADDRESS_REGEX = %r(([*+!.&#\$|\'\\%\/0-9a-z^_`{}=?~:-]+)@(([0-9a-z-]+\.)+[0-9a-z]{2,}))i
    TELEPHONE_NUMBER_REGEX = %r([0０]([0-9０-９]{9,10}|[0-9０-９]{1,3}([ー\-][0-9０-９]{2,4}){2}))
  end

end
