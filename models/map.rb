# -*- coding: utf-8 -*-

class MapBookmark < Sequel::Model(:map_bookmarks)
  many_to_one :user
  plugin :serialization, :json, :markers
  set_default_values_custom :markers, "[]"
end
