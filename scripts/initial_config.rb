#!/usr/bin/env ruby
require './init'
require 'io/console'
pass1 = nil
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
}
DB.transaction{
  hash = Kagetra::Utils.hash_password(pass1)
  if MyConf.first(name: "shard_password").nil? then
    MyConf.create(name: "shared_password",value: Kagetra::Utils.hash_password(pass1))
    puts "saved shared password to db"
  end
  if MyConf.first(name: "addrbook_confirm_enc").nil? then
    Kagetra::Utils.set_addrbook_password(pass1)
    puts "saved address book password to db"
  end
  if UserAttributeKey.all.count == 0 then
    CONF_INITIAL_ATTRIBUTES.each_with_index{|(k,v),i|
      key = UserAttributeKey.create(name:k,index:i)
      v.each_with_index{|x,idx|
        key.values.create(index:idx,value:x)
      }
    }
    puts "created user attributes"
  end
  if User.first(name: "admin").nil? then
    User.create(name: "admin", furigana: "admin",password_hash: hash[:hash], password_salt: hash[:salt], admin: true)
    puts "created user 'admin' and set password to shared password "
  end
  User.all(password_hash: nil).each{|user|
    hash = Kagetra::Utils.hash_password(pass1)
    puts "setting password of #{user.name}"
    user.update(password_hash: hash[:hash], password_salt: hash[:salt])
  }
  puts "updated all users which password is empty to shared password"
}
