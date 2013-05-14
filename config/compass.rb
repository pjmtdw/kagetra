if defined?(Sinatra)
  project_path = Sinatra::Application.root
  environment = :development
else
  css_dir = File.join('public','stylesheets')
  relative_assets = true
  environment = :production
end
sass_dir = File.join('views','stylesheets')
images_dir = File.join('public','images')
http_path = '/'
http_images_path = '/images'
http_stylesheets_path = '/stylesheets'
