#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

# 実行する前に`yum install exiv2` しておくこと
# iPhoneのSafariはEXIFのOrientationをサポートしている
# 景虎はOrientationをサポートしていないブラウザのためにRmagickのauto_orientを使って回転を行う．
# 葉隠以前ではその辺をサポートしていないためOrientationをTop-leftにする必要がある．
# このディレクトリの一つ上の階層で
# $ echo adjust_exif_orientation | bundle exec tux -r ./hagakure/adjust_exif_orientation.rb | tee adjust_exif_orientation.log
# で実行する
def adjust_exif_orientation
  AlbumItem.aggregate(fields:[:id]).each{|item_id|
    item = AlbumItem.get(item_id)
    path = File.join(G_STORAGE_DIR,"album",item.photo.path)
    img = Magick::Image::read(path).first
    orient = Hash[img.get_exif_by_entry("Orientation")]["Orientation"]
    next if orient.nil? or orient == "1"
    p [item_id,orient,item.photo.path.to_s]
    `exiv2 -M "set Exif.Image.Orientation 1" modify "#{path}"`
    app.update_thumbnail(item)
  }
  nil
end
