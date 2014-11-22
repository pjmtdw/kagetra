# -*- coding: utf-8 -*-
class MainApp < Sinatra::Base
  ALBUM_SEARCH_PER_PAGE = 50
  ALBUM_RECENT_GROUPS = 6
  ALBUM_EVENT_COMPLEMENT_DAYS = 3
  ALBUM_EVENT_COMPLEMENT_LIMIT = 50
  def album_group_info(group)
    r = group.select_attr(:id,:name,:start_at,:item_count).merge({type:"group"})
    ic = group.item_count || 0
    if ic > 0 then
      cc = group.has_comment_count || 0
      tc = group.has_tag_count || 0
      if ic - cc > 0 then
        r[:no_comment] = (((ic-cc)/ic.to_f)*100).to_i
      end
      if ic - tc > 0 then
        r[:no_tag] = (((ic-tc)/ic.to_f)*100).to_i
      end
    end
    r
  end
  namespace '/api/album' do
    get '/random' do
      r = rand(AlbumItem.count)
      item = AlbumItem.offset(r).first
      group_items = item.group.items_dataset.order(Sequel.asc(:group_index)).map(&:id)
      {id:item.id,group_items: group_items}
    end
    get '/year/:year' do
      year = if params[:year] == "_else_" then nil else params[:year] end
      groups = AlbumGroup.where(year:year, dummy:false).map{|x|
        album_group_info(x)
      }
      dummies = AlbumGroup.first(year:year, dummy:true)
      items = if dummies then dummies.items.map{|x|x.select_attr(:id,:name,:date).merge({type:"item"})} else [] end
      {list:groups+items}
    end
    get '/group/:gid' do
      group = AlbumGroup[params[:gid].to_i]
      halt 404 if group.nil?
      r = group.select_attr(:id,:name,:year,:place,:comment,:start_at,:end_at)
      r[:event_id] = group.event.id if group.event
      tags = Hash.new{[]}
      owners = Hash.new{[]}
      r[:items] = group.items_dataset.order(Sequel.asc(:group_index)).map{|x|
        if x.tag_names then
          x.tag_names.each{|t|
            tags[t] <<= x.id
          }
        end
        if not x.owner_id.nil? then
          owners[x.owner_id] <<= x.id
        end
        no_tag = x.tag_count == 0
        no_comment = x.comment.to_s.empty?
        data = x.id_with_thumb
        if no_tag then
          data[:no_tag] = 1
        end
        if no_comment then
          data[:no_comment] = 1
        end
        data
      }
      users = User.where(id:owners.keys).to_hash(:id,:name)
      r[:owners] = owners.to_a.map{|k,v|
        [users[k]||"不明",v]
      }.sort_by{|k,v|v.size}.reverse
      r[:tags] = tags.sort_by{|k,v|v.size}.reverse
      r[:deletable] = @user.admin || group.owner_id == @user.id
      r
    end
    delete '/group/:gid' do
      with_update{
        group = AlbumGroup[params[:gid].to_i]
        if group.nil?.! then
              group.destroy
        end
      }
    end
    put '/group/:gid' do
      group = AlbumGroup[params[:gid].to_i]
      with_update{
        if @json.has_key?("item_order") then
          @json["item_order"].each_with_index{|item,i|
            AlbumItem[item].update(group_index:i)
          }
          @json.delete("item_order")
        end
        if @json.has_key?("add_rotate") then
          @json["add_rotate"].each{|k,v|
            item = AlbumItem[k]
            item.update(rotate:(item.rotate.to_i+v)%360)
            update_thumbnail(item)
          }
          @json.delete("add_rotate")
        end
        group.update(@json.except("id"))
      }
    end
    get '/item/:id' do
      item = AlbumItem[params[:id].to_i]
      halt 404 if item.nil?
      r = item.select_attr(:id,:rotate,:name,:place,:date,:comment,:daily_choose,:comment_revision)
      r[:owner_name] = if item.owner.nil? then "" else item.owner.name end
      photo = item.photo
      (width,height) = case item.rotate.to_i
                       when 0,180 then [photo.width,photo.height]
                       else [photo.height,photo.width]
                       end
      r.merge!(photo:photo.select_attr(:id).merge(width:width,height:height))
      r[:group] = item.group.select_attr(:dummy,:year,:id,:name)
      r[:tags] = item.tags.map{|t|
        rr = t.select_attr(:id,:name,:radius)
        (xx,yy) = [t.coord_x,t.coord_y]
        (cx,cy) = case item.rotate.to_i
                when 0
                  [xx,yy]
                when 90
                  [width-yy,xx]
                when 180
                  [width-xx,height-yy]
                when 270
                  [yy,height-xx]
                end
        rr.merge({coord_x:cx,coord_y:cy})
      }
      r[:relations] = item.relations.map(&:id_with_thumb)
      r[:deletable] = @user.admin || item.owner_id == @user.id
      r
    end
    put '/item/:id' do
      item = AlbumItem[params[:id].to_i]
      with_update{
        orig_rotate = @json["orig_rotate"]
        @json.delete("orig_rotate")
        if @json.has_key?("tag_edit_log")
          @json["tag_edit_log"].each{|k,v|
            (cmd,obj) = v
            case cmd
            when "update_or_create"
              (xx,yy) = [obj["coord_x"],obj["coord_y"]]
              (width,height) = [item.photo.width,item.photo.height]
              (cx,cy) = case orig_rotate.to_i
                      when 0
                        [xx,yy]
                      when 90
                        [yy,height-xx]
                      when 180
                        [width-xx,height-yy]
                      when 270
                        [width-yy,xx]
                      end
              obj["coord_x"] = cx
              obj["coord_y"] = cy
              if k.to_i < 0 then
                obj.delete("id")
                obj["album_item_id"] = item.id
                AlbumTag.create(obj)
              else
                tag = AlbumTag[obj["id"]]
                obj.delete("id")
                tag.update(obj) if tag
              end
            when "destroy"
              if k.to_i >= 0 then
                t = AlbumTag[k.to_i]
                if t.nil?.! then
                  t.destroy
                end
              end
            end
          }
          @json.delete("tag_edit_log")
        end
        if @json.has_key?("relations")
          rids_old = item.relations.map(&:id)
          rids_new = @json["relations"].map{|r|r["id"] }
          adds = rids_new - rids_old
          dels = rids_old - rids_new
          if dels.empty?.! then
            AlbumRelation.where(source_id:item.id,target_id:dels).destroy
            AlbumRelation.where(source_id:dels,target_id:item.id).destroy
          end
          adds.each{|i|
            AlbumRelation.create(source_id:item.id,target_id:i)
          }
          @json.delete("relations")
        end
        item.do_after_tag_updated
        (updates,updates_patch) = make_comment_log_patch(item,@json,"comment","comment_revision")
        if updates then @json.merge!(updates) end
        item.update(@json.except("id"))
        if updates_patch
          AlbumCommentLog.create(updates_patch.merge({user:@user,album_item:item}))
        end
      }
    end
    get '/years' do
      aggr = AlbumGroup.select_group(:year).select_append{sum(item_count).as(sum_item_count)}.order(Sequel.desc(:year)).distinct
      comment_updated = AlbumItem.max(:comment_updated_at)
      if comment_updated then
        comment_updated = comment_updated.strftime("%m月%d日 %H:%M")
      end
      total = aggr.map{|x|x[:sum_item_count]}.sum
      recent = AlbumGroup.where(dummy:false).order(Sequel.desc(:created_at)).limit(ALBUM_RECENT_GROUPS).map{|x|
        album_group_info(x)
      }
      list = aggr.map{|x|[x.year,x[:sum_item_count]]}
      {list: list,total: total,recent:{list:recent}, comment_updated:comment_updated}
    end
    post '/search' do
      qs = params[:qs]
      page = if params[:page] then params[:page].to_i else 1 end
      dataset = AlbumItem.dataset
      if /(?:^|\s)([0-9\-]+)(?:$|\s)/ =~ qs then
        qs = $` + " " + $'
        mt = $1
        (year_s,year_e) = nil
        if mt.end_with?("-") then
          year_s = mt.delete("-").to_i
        elsif mt.start_with?("-") then
          year_e = mt.delete("-").to_i
        elsif mt.include?("-") then
          (year_s,year_e) = mt.split("-")
        else
          (year_s,year_e) = [mt.to_i]*2
        end
        if year_s then
          dataset = dataset.where{date >= Date.new(year_s.to_i,1,1)}
        end
        if year_e then
          dataset = dataset.where{date < Date.new(year_e.to_i+1,1,1)}
        end
      end
      qs.strip.split(/\s+/).each{|q|
        qb = [:name,:place,:comment,:tag_names].map{|sym|
          # TODO: escape query
          Sequel.like(sym,"%#{q}%")
        }.inject(:|)
        dataset = dataset.where(qb)
      }
      chunks = dataset.order(Sequel.desc(:date)).paginate(page,ALBUM_SEARCH_PER_PAGE)
      list = chunks.map(&:id_with_thumb)
      {
        list: list,
        pages: chunks.page_count,
        cur_page: page,
        count: chunks.pagination_record_count,
        qs: params[:qs]
      }
    end
    post '/complement_event' do
      group = AlbumGroup[params[:group_id]]
      query = params[:q]
      results = if query.empty? then
                  if group.start_at then
                    st = group.start_at - ALBUM_EVENT_COMPLEMENT_DAYS
                    ed = group.start_at + ALBUM_EVENT_COMPLEMENT_DAYS
                    
                    Event.where{ (date >= st) & (date <= ed)}
                         .where(done:true,kind:Event.kind__contest)
                         .order(Sequel.desc(:date))
                         .map{|x|
                           {id:x.id,text:"#{x.name}@#{x.date}"}
                         }
                  else
                    []
                  end
                else
                  qr = Event.order(Sequel.desc(:date))
                  if /\d{4}/ =~ query then
                    year = $&.to_i
                    query.sub!(/\s*\d{4}\s*/,"")
                    qr = qr.where{ (date >= Date.new(year,1,1)) & (date < Date.new(year+1,1,1))}
                  end
                  query.gsub!(/\s+/,"")
                  # TODO: escape query
                  qr.where(Sequel.like(:name,"%#{query}%")).limit(ALBUM_EVENT_COMPLEMENT_LIMIT).map{|x|
                    {id:x.id,text:"#{x.name}@#{x.date}"}
                  }
                end
      {results:results}

    end
    get '/thumb_info/:id' do
      item = AlbumItem[params[:id].to_i]
      item.id_with_thumb
    end
    ALBUM_COMMENTS_PER_PAGE = 40
    get '/all_comment_log' do
      page = if params[:page].to_s.empty?.! then params[:page].to_i else 1 end
      chunks = AlbumItem.where{comment_revision >= 1}.where(Sequel.~(comment_updated_at:nil)).order(Sequel.desc(:comment_updated_at),Sequel.desc(:id)).paginate(page,ALBUM_COMMENTS_PER_PAGE)
      res = chunks.map{|x|
        dff = x.each_diff_htmls_until(1).to_a.last
        r = x.id_with_thumb
        r[:diff_html] = dff[:html]
        log = dff[:log]
        r[:log] = {
          date: log.created_at.strftime("%Y-%m-%d"),
          user_name: if not log.user.nil? then log.user.name else "" end
        }
        r
      }.compact
      data = {list:res,next_page:page+1}
      if page > 1 then
        data[:prev_page] = page-1
      end
      data
    end

    post '/search_group' do
      query = params[:q]
      qs = query.split(/\s+/)
      res = AlbumGroup.where(Sequel.~(id:params[:exclude].to_i))
      qs.each{|q|
        if /^\d{4}$/=~ q then
          res = res.where(year:q.to_i)
        else
          res = res.where(Sequel.like(:name,"%#{q}%"))
        end
      }
      results = res.order(Sequel.desc(:start_at)).map{|x|
        {
          id:x.id,
          text:x.name.to_s + "@#{x.start_at}"
        }
      }
      {results:results}
    end
    post '/move_group' do
      with_update{
        to_group = AlbumGroup[@json["group_id"].to_i]
        index = to_group.items_dataset.max(:group_index) || -1
        from_groups = {}
        AlbumItem.where(id:@json["item_ids"]).order(Sequel.asc(:group_index)).each{|item|
          next if item.group_id == to_group.id
          from_groups[item.group_id] = true
          index += 1
          item.update(group_id:to_group.id, group_index:index)
        }
        to_group.update_count
        AlbumGroup.where(id:from_groups.keys).each{|x|
          x.update_count
        }
      }
    end
    post '/update_attrs' do
      with_update{
        item_ids = @json["item_ids"]
        @json.delete("item_ids")
        AlbumItem.where(id:item_ids).each{|x|x.update(@json)}
      }
    end
    delete '/item/:id' do
      item = AlbumItem[params[:id].to_i]
      halt 403 unless (@user.admin or item.owner_id == @user.id)
      if item.nil?.! then
        with_update{
          ag = item.group
          item.destroy
          ag.update_count
        }
      end
    end
    delete '/delete_items/:group_id' do
      item_ids = @json["item_ids"]
      with_update{
        ag = AlbumGroup[params[:group_id]]
        cond = if @user.admin then {} else {owner_id:@user.id} end
        items = AlbumItem.where(cond.merge({id:item_ids}))
        deleted_ids = items.map(&:id)
        items.destroy
        ag.update_count
        {list:deleted_ids}
      }
    end
    post '/tag_complete' do
      items = AlbumItem.where(group_id:params[:group_id].to_i)
      tags = AlbumTag.where(Sequel.like(:name,"%#{params[:q]}%")).where(album_item:items).map(&:name)
      list = User.where(Sequel.like(:name,"%#{params[:q]}%")).order(Sequel.desc(:updated_at)).map(&:name)
      {results:(tags+list).uniq}
    end
    post '/set_event' do
      with_update{
        gid = @json["album_group_id"].to_i
        eid = @json["event_id"].to_i
        if eid == -1 then
          AlbumGroupEvent.first(album_group_id:gid).destroy
        else
          AlbumGroupEvent.update_or_create(album_group_id:gid){|x|
            x.event_id = eid
          }

        end
      }
    end
    get '/stat' do
      uploaders = AlbumItem.group_and_count(:owner_id).where(Sequel.~(owner_id:nil)).order(Sequel.desc(:count))
      uploader_stat = [] 
      prev_count = nil
      rank = 1
      uploaders.to_enum.with_index(1){|x,index|
        count = x[:count]
        owner_id = x[:owner_id]
        if count != prev_count
          rank = index
          prev_count = count
        end
        is_mine = (owner_id == @user.id)
        if rank <= 20 or is_mine
          uploader_stat << [rank,count,owner_id,is_mine]
        end
      }

      uploader_names = User.where(id:uploader_stat.map{|x|x[2]}).to_hash(:id,:name)

      tags = AlbumTag.group_and_count(:name).order(Sequel.desc(:count)).limit(20)
      tag_stat = []
      prev_count = nil
      has_mine = false
      tags.to_enum.with_index(1){|x,index|
        count = x[:count]
        name = x[:name]
        if count != prev_count
          rank = index
          prev_count = count
        end
        is_mine = (name == @user.name)
        has_mine ||= is_mine
        tag_stat << [rank,count,name,is_mine]
      }
      if not has_mine then
        count = AlbumTag.where(name:@user.name).count
        tag_stat << ["??",count,@user.name,true]
      end
      {uploader_stat:uploader_stat,uploader_names:uploader_names,tag_stat:tag_stat}
    end
  end
  get '/album' do
    haml :album
  end

  # 縦横比は保持したまま画素数を増減する
  def resize_to_pixels!(img,pixels)
    orig_px = img.columns * img.rows
    scale = Math.sqrt(pixels.to_f / orig_px.to_f)
    img.resize!(scale)
  end

  def process_image(group,index,orig_filename,tfile)
    abs_path = Pathname.new(tfile).realpath
    item = AlbumItem.create(
      group.select_attr(:place,:name).merge({
        group_id:group.id,
        date:group.start_at,
        group_index:index,
        owner_id:@user.id
    }))
    rel_path = abs_path.relative_path_from(Pathname.new(File.join(G_STORAGE_DIR,"album")).realpath)
    img = Magick::Image::read(abs_path).first
    prev_columns = img.columns
    prev_rows = img.rows
    rotated = img.auto_orient!.nil?.!
    resize_to_pixels!(img,CONF_ALBUM_LARGE_SIZE)
    if prev_columns != img.columns or prev_rows != img.rows or rotated
      img.write(abs_path){self.quality = CONF_ALBUM_LARGE_QUALITY}
    end

    AlbumPhoto.create(
      album_item_id:item.id,
      path:rel_path,
      format: img.format,
      width: img.columns,
      height: img.rows
    )
    resize_to_pixels!(img,CONF_ALBUM_THUMB_SIZE)
    img.write(abs_path.to_s+"_thumb"){self.quality = CONF_ALBUM_THUMB_QUALITY}
    AlbumThumbnail.create(
      album_item_id:item.id,
      path:rel_path.to_s+"_thumb",
      format: img.format,
      width: img.columns,
      height: img.rows
    )
    img.destroy!
  end

  def update_thumbnail(item)
    base = File.join(G_STORAGE_DIR,"album")
    img = Magick::Image::read(File.join(base,item.photo.path)).first
    resize_to_pixels!(img,CONF_ALBUM_THUMB_SIZE)
    img.rotate!(item.rotate.to_i)
    img.write(File.join(base,item.thumb.path)){self.quality = CONF_ALBUM_THUMB_QUALITY}
    item.thumb.update(width:img.columns,height:img.rows)
    img.destroy!
  end
  post '/album/upload' do
    res = with_update{
      group = if params[:group_id] then
        AlbumGroup[params[:group_id]]
      else
        attrs = params.select_attr("start_at","end_at","place","name","comment")
        if attrs["start_at"].to_s.empty? then attrs["start_at"] = nil end
        if attrs["end_at"].to_s.empty? then attrs["end_at"] = nil end
        attrs["owner_id"] = @user.id
        AlbumGroup.create(attrs)
      end
      pfile = params[:file]
      if pfile.nil? then
        {result:"OK",group_id:group.id}
      else
        tempfile = pfile[:tempfile]
        filename = pfile[:filename]
        min_index = 1 + (group.items_dataset.max(:group_index) || -1)
        date = Date.today
        target_dir = File.join(G_STORAGE_DIR,"album",date.year.to_s,date.month.to_s)
        FileUtils.mkdir_p(target_dir)
        case filename.downcase
        when /\.zip$/
          tmp = Dir.mktmpdir(nil,target_dir)
          Zip::File.open(tempfile).select{|x|x.file? and [".jpg",".png",".gif"].any?{|s|x.name.downcase.end_with?(s)}}
            .to_enum.with_index(min_index){|entry,i|
              fn = File.join(tmp,i.to_s)
              File.open(fn,"w"){|f|
                f.write(entry.get_input_stream.read)
              }
              process_image(group,i,entry.name,fn)
            }
          {result:"OK",group_id:group.id}
        when /\.jpg$/, /\.png$/, /\.gif$/
          tfile = Kagetra::Utils.unique_file(@user,["img-",".dat"],target_dir)
          FileUtils.cp(tempfile.path,tfile)
          process_image(group,min_index,filename,tfile)
          {result:"OK",group_id:group.id}
        else
          {_error_:"ファイルの拡張子が間違いです: #{filename.downcase}"}
        end
      end
    }
    "<div id='response'>#{res.to_json}</div>"
  end
  def send_photo(p,rotate)
    content_type "image/#{p.format.downcase}"
    path = File.join(G_STORAGE_DIR,"album",p.path)
    ext = case p.format.downcase
          when "jpeg" then "jpg"
          else p.format.downcase
          end
    prefix =  if p.class == AlbumThumbnail then
                p.album_item_id.to_s + "_thumb"
              else
                p.album_item_id
              end
    filename = "#{prefix}.#{ext}"
    if rotate == 0
      send_file(path,disposition:"inline",filename:filename)
    else
      attachment(filename,"inline")
      last_modified p.updated_at
      img = Magick::Image::read(path).first
      img.rotate!(rotate)
      blob = img.to_blob
      img.destroy!
      blob
    end
  end

  namespace '/static/album' do
    # キャッシュを防ぐために回転の度数ごとに別URLにする
    get '/thumb/:id.?:rotate?' do
      p = AlbumThumbnail[params[:id].to_i]
      # サムネイルは作成時にrotate済みなのでそのまま送る
      send_photo(p,0)
    end
    get '/photo/:id.?:rotate?' do
      p = AlbumPhoto[params[:id].to_i]
      send_photo(p,params[:rotate].to_i)
    end
  end
end
