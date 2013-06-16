#!/usr/bin/env ruby
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
  User.update_or_create({name: "admin", furigana: "admin"},{password_hash: hash[:hash], password_salt: hash[:salt], admin: true})
  puts "created user 'admin' and set password to shard_password "

  MyConf.update_or_create({name: "shared_password"}, {value: Kagetra::Utils.hash_password(pass1)})
  puts "saved shared password to db"
  User.all(password_hash: nil).each{|user|
    hash = Kagetra::Utils.hash_password(pass1)
    puts "setting password of #{user.name}"
    user.update(password_hash: hash[:hash], password_salt: hash[:salt])
  }
  puts "updated all users which password is empty to shard password"
}
