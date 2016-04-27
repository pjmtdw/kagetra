# -*- coding: utf-8 -*-
# License of this software is described in LICENSE file.

# Change this number whenever you changed the .coffee/.js/.scss/.css/.haml file
# TODO: automatically increase this version
G_RESOURCE_VERSION = 26

require_relative '../conf'
require 'bundler'
require 'sequel'
require 'sinatra'
require 'sinatra/namespace'
require 'sinatra/content_for'
if development? then
  require 'sass/plugin/rack'
  require 'sinatra/reloader'
end
require 'logger'
require 'haml'

require 'json'
require 'base64'
require 'digest'
require 'nkf'
require 'redcarpet'
require_relative '../libs/diff_match_patch-ruby/diff_match_patch.rb'
G_DIMAPA = DiffPatchMatch.new
require 'RMagick'
require 'zip'

require 'nokogiri'

require 'spreadsheet'

require 'openssl'
require 'securerandom'
require 'tempfile'
require 'resolv'

require_relative '../models/init'
require_relative './app'
require_relative './utils'
require_relative './helpers/init'
require_relative '../routes/init'

require_relative '../mobile/init'
