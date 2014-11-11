# -*- coding: utf-8 -*-

class AddrBook < Sequel::Model(:addr_books)
  many_to_one :user
  many_to_one :album_item
end
