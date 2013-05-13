HAGAKURE_BASE="/home/maho/hagakure/subdomains/hagakure/httpdocs"
Dir.chdir(File.join(File.dirname(File.expand_path(__FILE__)),".."))
require 'data_mapper'
require 'dm-sqlite-adapter'
require './model'
File.readlines(File.join(HAGAKURE_BASE,"txts","namelist.cgi")).each_with_index{|code,index|
  next if index == 0
  code.chomp!
  File.open(File.join(HAGAKURE_BASE,"passdir","#{code}.cgi")){|f|
    f.set_encoding("Shift_JIS","UTF-8")
    f.each{|line|
      line.chomp!
      (uid,name,password_hash,login_num,last_login,user_agent) = line.split("\t")
      (uid,auth) = uid.split("<>")
      (name,furigana,zokusei) = name.split("+")
      puts name
      User.create(:id => uid, :name => name, :furigana => furigana)
    }
  }
}
