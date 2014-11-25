#!/usr/bin/env ruby
begin
  require_relative '../inits/init'
rescue Sequel::DatabaseConnectionError => e
  puts "DatabaseConnectionError: #{e.message}"
  exit
end

begin
  # try query
  User.first
rescue Sequel::DatabaseError => e
  puts "no table found. executing migration."
  # exec migrate
  Sequel.extension :migration, :core_extensions
  Sequel::Migrator.apply(DB, "migrate", 9)
  puts "migration done. re-execute this script!"
  exit
end

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
        UserAttributeValue.create(attr_key:key,index:idx,value:x)
      }
    }
    puts "created user attributes"
  end
  admin = User.first(name: "admin")
  if admin.nil? then
    admin = User.create(name: "admin", furigana: "admin",password_hash: hash[:hash], password_salt: hash[:salt], admin: true)
    puts "created user 'admin' and set password to shared password "
  end
  User.where(password_hash: nil).each{|user|
    hash = Kagetra::Utils.hash_password(pass1)
    puts "setting password of #{user.name}"
    user.update(password_hash: hash[:hash], password_salt: hash[:salt])
  }
  puts "updated password of all users which password is empty to shared password"
  WikiItem.create(title:"Home",body:"This is home page of this wiki",revision:1,owner_id:admin.id)
}
