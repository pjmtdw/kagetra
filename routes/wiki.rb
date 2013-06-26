class MainApp < Sinatra::Base 
  MARKDOWN = Redcarpet::Markdown.new(Redcarpet::Render::HTML,tables:true,fenced_code_blocks:true)
  namespace '/api/wiki' do
    get '/item/:id' do
      text = WikiItem.get(params[:id].to_i).body
      {html: MARKDOWN.render(text)}
    end
  end
  get '/wiki' do
    user = get_user
    haml :wiki,{locals: {user: user}}
  end
end
