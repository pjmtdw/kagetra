require 'bundler'
require 'sinatra'
require 'sinatra/reloader' if development?
require 'sinatra/namespace'
require 'sass/plugin/rack'
require 'json'
require 'data_mapper'
require 'dm-sqlite-adapter'
require 'securerandom'
require './helpers'
require './model'
require './main_app'

CONF_APP_NAME='景虎'

Bundler.require(:default)

# Auto-Compile Sass to CSS
Sass::Plugin.options[:style] = :compressed
use Sass::Plugin::Rack

# Auto-Compile CoffeeScript to JavaScript
use Rack::Coffee, root: 'public', urls: '/javascripts'

run MainApp
