# -*- coding: utf-8 -*-
require 'bundler'

require 'sinatra'
require 'sinatra/reloader' if development?
require 'sinatra/namespace'
require 'sass/plugin/rack' if development?

require 'json'
require 'base64'
require 'data_mapper'
require 'dm-sqlite-adapter'

require 'openssl'
require 'securerandom'

require './app'
require './routes/init'
require './helpers/init'
require './models/init'
require './utils'

CONF_APP_NAME='景虎'

