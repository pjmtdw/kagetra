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
  puts "saving shared password to db"
  MyConf.create(:name => "shared_password", :value => Kagetra.hash_password(pass1))
}
