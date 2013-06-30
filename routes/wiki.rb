class MainApp < Sinatra::Base 
  ATTACHED_LIST_PER_PAGE = 50
  MARKDOWN = Redcarpet::Markdown.new(
    Redcarpet::Render::HTML.new(hard_wrap:true),tables:true,fenced_code_blocks:true)
  namespace '/api/wiki' do
    def render_wiki(body_text,public_mode)
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
    get '/item/:id' do
      txt = WikiItem.get(params[:id].to_i).body
      {html: render_wiki(txt,false)}
    end
    get '/attached_list/:id' do
      page = (params[:page] || 1).to_i
      chunks = WikiAttachedFile.all(wiki_item_id:params[:id].to_i,order:[:created_at.desc]).chunks(ATTACHED_LIST_PER_PAGE) 
      pages = chunks.size
      list = chunks[page-1].map{|x|
        x.select_attr(:id,:orig_name,:description,:size).merge({
          date:x.created_at.to_date.strftime('%Y-%m-%d')
        })
      }
      {list: list, pages: pages, cur_page: page}
    end
  end
  get '/wiki' do
    user = get_user
    haml :wiki,{locals: {user: user}}
  end
  get '/static/wiki/attached/:id' do
    attached = WikiAttachedFile.get(params[:id].to_i)
    send_file("../mytoma/storage/wiki/#{attached.path}",filename:attached.orig_name)
  end
end