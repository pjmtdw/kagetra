# -*- coding: utf-8 -*-
class MainApp < Sinatra::Base 
  ATTACHED_LIST_PER_PAGE = 50
  WIKI_ALL_PER_PAGE = 50
  MARKDOWN = Redcarpet::Markdown.new(
  Redcarpet::Render::HTML.new(hard_wrap:true),tables:true,fenced_code_blocks:true)
  namespace '/api/wiki' do
    def render_wiki(body_text,public_mode)
      body_text = body_text.clone
      # 本文中に出現しないランダムな文字列生成
      gen_tag = ->(){
        loop{
          t = SecureRandom.base64(24).gsub(/\W/,"")
          break t unless body_text.include?(t)
        }
      }
      (tag_link,tag_private_s,tag_private_e) = Array.new(3){gen_tag.call}

      # [[ keyword | text ]] と [[ keyword ]] はWiki内リンク
      links = []
      body_text.gsub!(/\[\[((.+?)(\|(.+?))?)\]\]/).with_index(0){|_,i|
        links << $1
        # i は数字なので閉じタグは必要ない
        "#{tag_link}:#{i}:"
      }
      # /* */ で囲まれた部分は非公開
      body_text.gsub!(%r(/\*(.+?)\*\/)m){
        if not public_mode then
          "#{tag_private_s}:#{$1}:#{tag_private_e}"
        end
      }

      html = MARKDOWN.render(body_text)

      if not public_mode then
        html.gsub!(%r(#{tag_private_s}:(.*?):#{tag_private_e})m){
          %(<span class="private">#{$1}</span>)
        }
      end

      html.gsub!(/#{tag_link}:(\d+):/){
        (keyword,text) = links[$1.to_i].split('|').map{|x|x.strip}
        text ||= keyword
        item = WikiItem.first(title:keyword)
        if item.nil? then
          %(<a class="link-new" data-link-new="#{Rack::Utils.escape_html(keyword)}">#{text}</a>)
        else
          %(<a class="link-page" data-link-id="#{item.id}">#{text}</a>)
        end
      }
      html
    end
    get '/item/all' do
      page = if params[:page] then params[:page].to_i else 1 end
      # chunksを使うときはorderに同じ物がある可能性があるものを指定するとバグるので:id.descも一緒に指定すること
      chunks = WikiItem.all(order:[:updated_at.desc,:id.desc]).chunks(WIKI_ALL_PER_PAGE)
      html = "<ul>" + chunks[page-1].map{|x|
          "<li>[#{x.updated_at.to_date}] <a data-link-id='#{x.id}' class='link-page'>#{x.title}</a></li>"
      }.join() + "</ul>"
      if page < chunks.size then
        html += "<a class='next-page' data-page-num='#{page+1}'>次のページ</a>"
      end
      {
        title: "全一覧",
        html: html
      }
    end
    get '/item/:id' do
      item = WikiItem.get(params[:id].to_i)
      r = item.select_attr(:title,:revision)
      if params[:edit].to_s.empty?.! then
        r[:body] = item.body
      else
        r[:html] = render_wiki(item.body,false)
      end
      r
    end
    delete '/item/:id' do
      item = WikiItem.get(params[:id].to_i)
      # destory するには関連するmodelを削除しないといけないけどそれはイヤなので deleted フラグを付けるだけ
      item.update(deleted:true)
    end

    def update_or_create_item(item)
      dm_response{
        WikiItem.transaction{
          new_body = @json["body"]
          if new_body.to_s.empty?.! then
            prev_body = if item then item.body else "" end
            if item
              # check for conflict
              if item.revision != @json["revision"]
                # if conflict then merge
                r_body = item.get_revision_body(@json["revision"])
                patches = G_DIMAPA.patch_make(r_body,new_body)
                (new_body,_) = G_DIMAPA.patch_apply(patches,prev_body)
              end
              rev = item.revision + 1
            else
              rev = 1
            end
            @json["body"] = new_body
            @json["revision"] = rev
          end
          if item then 
            item.update(@json)
          else 
            item = WikiItem.create(@json)
          end
          if @json.has_key?("body")
            patches = G_DIMAPA.patch_make(new_body,prev_body)
            patch = G_DIMAPA.patch_toText(patches)
            item.item_logs.create(revision:rev,user:@user,patch:patch)
          end
          item.attributes
        }
      }
    end

    put '/item/:id' do
      item = WikiItem.get(params[:id].to_i)
      update_or_create_item(item)
    end
    post '/item' do
      update_or_create_item(nil)
    end
    post '/preview' do
      {html: render_wiki(params[:body],false)}
    end

    get '/attached_list/:id' do
      page = (params[:page] || 1).to_i
      chunks = WikiAttachedFile.all(wiki_item_id:params[:id].to_i,order:[:created_at.desc,:id.desc]).chunks(ATTACHED_LIST_PER_PAGE) 
      pages = chunks.size
      list = chunks[page-1].map{|x|
        x.select_attr(:id,:orig_name,:description,:size).merge({
          date:x.created_at.to_date.strftime('%Y-%m-%d')
        })
      }
      {item_id:params[:id].to_i,list: list, pages: pages, cur_page: page}
    end
  end
  comment_routes("/api/wiki",WikiItem,WikiComment)
  get '/wiki' do
    haml :wiki
  end
  get '/static/wiki/attached/:id' do
    attached = WikiAttachedFile.get(params[:id].to_i)
    send_file("../mytoma/storage/wiki/#{attached.path}",filename:attached.orig_name)
  end
  post '/wiki/attached/:id' do
    halt 403 if @public_mode
    tempfile = params[:file][:tempfile]
    filename = params[:file][:filename]
    date = Date.today
    target_dir = File.join(G_STORAGE_DIR,"attached",date.year.to_s,date.month.to_s)
    FileUtils.mkdir_p(target_dir)
    target_file = Tempfile.new(["attached","dat"],target_dir)
    message = begin
      WikiAttachedFile.transaction{
        item = WikiItem.get(params[:id].to_i)
        FileUtils.cp(tempfile.path,target_file)
        item.attacheds.create(owner:@user,path:target_file,orig_name:filename,description:params[:description],size:File.size(target_file))
      }
      "送信成功しました"
    rescue
      FileUtils.rm(target_file)
      "送信失敗しました"
    end
    "#{message} [<a href='/wiki#page/#{params[:id]}'>戻る</a>]"
  end
end
