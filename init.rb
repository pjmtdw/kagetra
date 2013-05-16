# -*- coding: utf-8 -*-
require 'bundler'

require 'sinatra'
require 'sinatra/reloader' if development?
require 'sinatra/namespace'
require 'sass/plugin/rack'

require 'compass'

require 'json'
require 'base64'
require 'data_mapper'
require 'dm-sqlite-adapter'

require 'openssl'
require 'securerandom'

require './utils'
require './helpers'
require './model'
require './app'

CONF_APP_NAME='景虎'

