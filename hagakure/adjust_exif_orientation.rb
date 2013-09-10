#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
#require './init'

# iPhoneのSafariはEXIFのOrientationをサポートしている
# 景虎はOrientationをサポートしていないブラウザのためにRmagickのauto_orientを使って回転を行う．
# 葉隠以前ではその辺をサポートしていないためOrientationをTop-leftにする必要がある．
# このディレクトリの一つ上の階層で
# $ echo adjust_exif_orientation | bundle exec tux -r ./hagakure/adjust_exif_orientation.rb | tee hoge.log
# で実行する
def adjust_exif_orientation
  AlbumItem.aggregate(fields:[:id]).each{|item_id|
    item = AlbumItem.get(item_id)
    path = File.join(G_STORAGE_DIR,"album",item.photo.path)
    img = Magick::Image::read(path).first
    orient = Hash[img.get_exif_by_entry("Orientation")]["Orientation"]
    next if orient.nil? or orient == "1"
    p [item_id,orient,item.photo.path.to_s]
    new_path = path + ".new"
    `exif --tag "Orientation" --ifd="0" --set-value="1" -o "#{new_path}" "#{path}"`
    next unless File.exist?(new_path)
    FileUtils.mv(new_path,path,force:true)
    app.update_thumbnail(item)
  }
  nil
end
