# -*- coding: utf-8 -*-
class MainApp < Sinatra::Base
  ALBUM_SEARCH_PER_PAGE = 50
  namespace '/api/album' do
    get '/year/:year' do
      year = if params[:year] == "_else_" then nil else params[:year] end
      groups = AlbumGroup.all(year:year, dummy:false).map{|x|x.select_attr(:id,:name,:start_at,:item_count).merge({type:"group"})}
      items = AlbumGroup.all(year:year, dummy:true).items.map{|x|x.select_attr(:id,:name,:date).merge({type:"item"})}

      {list:groups+items} 
    end
    get '/group/:gid' do
      group = AlbumGroup.get(params[:gid].to_i)
      r = group.select_attr(:name,:year,:place,:comment,:start_at,:end_at)
      tags = {}
      r[:items] = group.items(order:[:group_index.asc]).map{|x|
        if x.tag_names then
          JSON.parse(x.tag_names).each{|t|
            tags[t] ||= []
            tags[t] << x.id
          }
        end
        x.select_attr(:id,:name).merge({
          thumb: x.thumb.select_attr(:id,:width,:height)
        })
      }
      r[:tags] = tags.sort_by{|k,v|v.size}.reverse
      r[:deletable] = @user.admin || group.owner_id == @user.id
      r
    end
    delete '/group/:gid' do
      group = AlbumGroup.get(params[:gid].to_i)
      if group.nil?.! then
        AlbumItem.transaction{
          group.update!(deleted:true)
        }
      end
    end
    put '/group/:gid' do
      group = AlbumGroup.get(params[:gid].to_i)
      dm_response{
        AlbumGroup.transaction{
          @json["item_order"].each_with_index{|item,i|
            AlbumItem.get(item).update(group_index:i)
          }
          @json.delete("item_order")
          group.update(@json)
        }
      }
    end
    get '/item/:id' do
      item = AlbumItem.get(params[:id].to_i)
      r = item.select_attr(:id,:name,:place,:date,:comment,:daily_choose,:comment_revision)
      r.merge!({photo:item.photo.select_attr(:id,:width,:height)})
      r[:group] = item.group.select_attr(:dummy,:year,:id,:name)
      r[:tags] = item.tags.map{|x|x.select_attr(:id,:name,:coord_x,:coord_y,:radius)}
      r[:relations] = item.relations.map{|x| x.select_attr(:id).merge({thumb:x.thumb.select_attr(:id,:width,:height)})}
      r[:deletable] = @user.admin || item.owner_id == @user.id
      r
    end
    put '/item/:id' do
      item = AlbumItem.get(params[:id].to_i)
      dm_response{
        AlbumItem.transaction{
          if @json.has_key?("daily_choose") then
            @json["daily_choose"] = @json["daily_choose"].nil?.!
          end
          if @json.has_key?("tag_edit_log")
            @json["tag_edit_log"].each{|k,v|
              (cmd,obj) = v
              case cmd
              when "update_or_create"
                if k.to_i < 0 then
                  obj.delete("id")
                  obj["album_item_id"] = item.id
                  AlbumTag.create(obj)
                else
                  AlbumTag.update(obj)
                end
              when "destroy"
                if k.to_i >= 0 then
                  t = AlbumTag.get(k.to_i)
                  if t.nil?.! then
                    t.destroy()
                  end
                end
              end
            }
            @json.delete("tag_edit_log")
          end
          if @json.has_key?("relations")
            rids_old = item.relations.map{|r|r.id }
            rids_new = @json["relations"].map{|r|r["id"] }
            adds = rids_new - rids_old
            dels = rids_old - rids_new
            if dels.empty?.! then
              AlbumRelation.all(source_id:item.id,target_id:dels).destroy()
              AlbumRelation.all(source_id:dels,target_id:item.id).destroy()
            end
            adds.each{|i|
              item.album_relations_r.create(target_id:i)
            }
            @json.delete("relations")
          end
          item.do_after_tag_updated
          (updates,updates_patch) = make_comment_log_patch(item,@json,"comment","comment_revision")
          if updates then @json.merge!(updates) end
          item.update(@json)
          if updates_patch
            item.comment_logs.create(updates_patch.merge({user:@user}))
          end
        }
      }
    end
    delete '/item/:id' do
      item = AlbumItem.get(params[:id].to_i)
      if item.nil?.! then
        AlbumItem.transaction{
          ag = item.group
          item.update!(deleted:true)
          ag.update_count
        }
      end
    end
    get '/years' do
      aggr = AlbumGroup.aggregate(:item_count.sum, fields:[:year], unique: true, order: [:year.desc])
      total = aggr.map{|x|x[1]}.sum
      {list: aggr,total: total}
    end
    post '/search' do
      cond = {}
      qs = params[:qs]
      page = if params[:page] then params[:page].to_i else 1 end
      if /(?:^|\s)([0-9\-]+)(?:$|\s)/ =~ qs then
        qs = $` + " " + $'
        mt = $1
        (year_s,year_e) = nil
        if mt.end_with?("-") then
          year_s = mt.gsub("-","").to_i
        elsif mt.start_with?("-") then
          year_e = mt.gsub("-","").to_i
        elsif mt.include?("-") then
          (year_s,year_e) = mt.split("-")
        else
          (year_s,year_e) = [mt.to_i]*2
        end
        cond[:date.gte] = Date.new(year_s.to_i,1,1) unless year_s.nil?
        cond[:date.lt] = Date.new(year_e.to_i+1,1,1) unless year_e.nil?
      end
      qx = AlbumItem.all(id:-1) # 存在しないクエリ
      ss = qs.strip.split(/\s+/).map{|x| "%#{x}%" }
      [:name,:place,:comment,:tag_names].each{|sym|
        q = AlbumItem.all(cond)
        ss.each{|x|
          q &= AlbumItem.all(sym.like => x)
        }
        qx |= q
      }
      chunks = qx.all(order:[:date.desc]).chunks(ALBUM_SEARCH_PER_PAGE)
      list = chunks[page-1].map{|x|
        {id:x.id,thumb:x.thumb.select_attr(:id,:width,:height)}
      }
      {
        list: list,
        pages: chunks.size,
        cur_page: page
      }
    end
    get '/thumb_info/:id' do
      item = AlbumItem.get(params[:id].to_i)
      item.select_attr(:id).merge({thumb:item.thumb.select_attr(:id,:width,:height)})
    end
    ALBUM_COMMENTS_PER_PAGE = 40
    get '/all_comment_log' do
      page = if params[:page].to_s.empty?.! then params[:page].to_i else 1 end
      chunks = AlbumItem.all(:comment_revision.gte => 1,:comment_updated_at.not=>nil,order:[:comment_updated_at.desc,:id.desc]).chunks(ALBUM_COMMENTS_PER_PAGE)
      res = chunks[page-1].map{|x|
        cur = x.comment
        prev = x.get_revision_comment(x.comment_revision - 1)
        next if prev == cur
        diffs = G_DIMAPA.diff_main(prev,cur)
        html = G_DIMAPA.diff_prettyHtml(diffs)
        r = x.select_attr(:id)
        r[:thumb] = x.thumb.select_attr(:width,:height,:id)
        r[:diff_html] = html
        log = x.comment_logs.first(revision:x.comment_revision)
        r[:log] = {
          date: log.created_at.strftime("%Y-%m-%d"),
          user_name: if not log.user.nil? then log.user.name else "" end
        }
        r
      }.compact
      {list:res,next_page:page+1}
    end
  end
  get '/album' do
    haml :album
  end

  def process_image(group,index,orig_filename,abs_path)
    item = AlbumItem.create(group.select_attr(:place,:name,:owner).merge({group_id:group.id,date:group.start_at,group_index:index}))
    rel_path = Pathname.new(abs_path).relative_path_from(Pathname.new(File.join(G_STORAGE_DIR,"album")).realpath)
    img = Magick::Image::read(abs_path).first
    new_img = img.resize_to_fit(800,800)
    if new_img.columns != img.columns or new_img.rows != img.rows
      new_img.write(abs_path){self.quality = 95}
    end

    item.update(photo:AlbumPhoto.create(
      album_item:item,
      path:rel_path,
      format: new_img.format,
      width: new_img.columns,
      height: new_img.rows
    ))
    thumb = img.resize_to_fit(200,200)
    thumb.write(abs_path+"_thumb"){self.quality = 80}
    item.update(thumb:AlbumThumbnail.create(
      album_item:item,
      path:rel_path.to_s+"_thumb",
      format: thumb.format,
      width: thumb.columns,
      height: thumb.rows
    ))

  end

  post '/album/upload' do
    res = dm_response{
      tempfile = params[:file][:tempfile]
      filename = params[:file][:filename]
      AlbumItem.transaction{
        attrs = params.select_attr(:start_at,:end_at,:place,:name,:comment)
        if attrs[:start_at].to_s.empty? then attrs[:start_at] = nil end
        if attrs[:end_at].to_s.empty? then attrs[:end_at] = nil end
        attrs[:owner] = @user
        group = AlbumGroup.create(attrs)
        date = Date.today
        target_dir = File.join(G_STORAGE_DIR,"album",date.year.to_s,date.month.to_s)
        FileUtils.mkdir_p(target_dir)
        case filename.downcase
        when /\.zip$/
          tmp = Dir.mktmpdir(nil,target_dir)
          Zip::ZipFile.new(tempfile).select{|x|x.file? and [".jpg",".png",".gif"].any?{|s|x.name.downcase.end_with?(s)}}
            .each_with_index{|entry,i|
              fn = File.join(tmp,i.to_s)
              File.open(fn,"w"){|f|
                f.write(entry.get_input_stream.read)
              }
              process_image(group,i,entry.name,fn)
            }
          {result:"OK",group_id:group.id}
        when /\.jpg$/, /\.png$/, /\.gif$/
          tfile = Tempfile.new(["img","dat"],target_dir)
          FileUtils.cp(tempfile.path,tfile)
          process_image(group,nil,filename,tfile.path)
          {result:"OK",group_id:group.id}
        else
          {_error_:"ファイルの拡張子が間違いです: #{filename.downcase}"}
        end
      }
    }
    "<div id='response'>#{res.to_json}</div>"
  end
  def send_photo(p)
    p1 = File.join(G_STORAGE_DIR,"album",p.path)
    p2 = File.join(CONF_HAGAKURE_BASE,"album",p.path)
    content_type "image/#{p.format.downcase}"
    [p1,p2].each{|path|
      send_file(path) if File.exist?(path)
    }
    halt 404 
  end

  namespace '/static/album' do
    get '/thumb/:id' do
      p = AlbumThumbnail.get(params[:id].to_i)
      send_photo(p)
    end
    get '/photo/:id' do
      p = AlbumPhoto.get(params[:id].to_i)
      send_photo(p)
    end
  end
end
