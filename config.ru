require 'bundler'

require 'sinatra'
require 'sinatra/reloader' if development?
require 'sinatra/namespace'
require 'sass/plugin/rack'

require 'compass'

require 'json'
require 'data_mapper'
require 'dm-sqlite-adapter'
require 'securerandom'

require './utils'
require './helpers'
require './model'
require './main_app'

CONF_APP_NAME='景虎'

Bundler.require(:default)

# Auto-Compile Sass to CSS
Sass::Plugin.options.merge!({
  :style => :compressed,
  :load_paths => [
    "#{Gem.loaded_specs['compass'].full_gem_path}/frameworks/compass/stylesheets",
    "#{Gem.loaded_specs['zurb-foundation'].full_gem_path}/scss"
    ],
  :template_location => {
    './views/sass' => './public/stylesheets'
  }
})
use Sass::Plugin::Rack

# Auto-Compile CoffeeScript to JavaScript
use Rack::Coffee, root: 'public', urls: '/javascripts'

run MainApp
