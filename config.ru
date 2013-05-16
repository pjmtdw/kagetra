require './init'

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
