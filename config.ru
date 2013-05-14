require 'bundler'

require 'sinatra'
require 'sinatra/reloader' if development?
require 'sinatra/namespace'

require 'compass'

require 'json'
require 'data_mapper'
require 'dm-sqlite-adapter'
require 'securerandom'

require './helpers'
require './model'
require './main_app'

CONF_APP_NAME='景虎'

Bundler.require(:default)

# Compass load path
Sass::Engine::DEFAULT_OPTIONS[:load_paths].tap do |load_paths|
  load_paths << "#{Gem.loaded_specs['compass'].full_gem_path}/frameworks/compass/stylesheets"
end

# Auto-Compile CoffeeScript to JavaScript
use Rack::Coffee, root: 'public', urls: '/javascripts'

run MainApp
