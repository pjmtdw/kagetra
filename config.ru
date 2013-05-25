require './init'

configure :development do
  Bundler.require(:default)
  # Auto-Compile Sass to CSS
  Sass::Plugin.options.merge!({
    style: :expanded,
    line_numbers: true,
    load_paths: [
      "#{Gem.loaded_specs['compass'].full_gem_path}/frameworks/compass/stylesheets",
      "#{Gem.loaded_specs['zurb-foundation'].full_gem_path}/scss"
      ],
    template_location: {
      './views/sass' => './public/css'
    }
  })
  use Sass::Plugin::Rack

  # Auto-Compile CoffeeScript to JavaScript
  use Rack::Coffee,
    root: 'views',
    urls: '/js',
    cache_compile: true
end
run MainApp
