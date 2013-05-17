require './init'
require 'io/console'
$stdin.noecho{|stdin|
  print "input shared password: "
  pass1 = stdin.readline.chomp
  puts
  print "input again: "
  pass2 = stdin.readline.chomp
  puts
  if pass1 != pass2 then
    puts "two passwords does not match"
    exit
  end

  hash = Kagetra::Utils.hash_password(pass1)
  User.create(:name => "admin", :furigana => "admin", :password_hash => hash[:hash], :password_salt => hash[:salt])
  puts "created user 'admin' with user_password == shard_password "
  MyConf.create(:name => "shared_password", :value => Kagetra::Utils.hash_password(pass1))
  puts "saved shared password to db"
}
