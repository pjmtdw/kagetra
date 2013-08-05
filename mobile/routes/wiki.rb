# -*- coding: utf-8 -*-
class MainApp < Sinatra::Base
  def mobile_show_bytes(x)
    if x < 1024
      "#{x} bytes"
    elsif x < 1048576
      "#{x/1024} KB"
    else
      "#{x/1048576} MB"
    end
  end
  namespace '/mobile/wiki' do
    get '/item/:id' do
      qs = if params.has_key?("page") then {page:params[:page]} else {} end
      res = call_api(:get,"/api/wiki/item/#{params[:id]}",qs)
      @title = res["title"]
      doc = Nokogiri::HTML(res["html"])
      doc.css("[data-link-id]").each{|x|
        x["href"] = "wiki/item/#{x['data-link-id']}"
      }
      doc.css("[data-page-num]").each{|x|
        x["href"] = "wiki/item/#{params[:id]}?page=#{x['data-page-num']}"
      }
      @html = doc.serialize
      mobile_haml :wiki
    end
    get '/attached_list/:id' do
      qs = if params.has_key?("page") then {page:params[:page]} else {} end
      @info = call_api(:get,"/api/wiki/attached_list/#{params[:id]}",qs)
      mobile_haml :wiki_attached
    end 
  end
  get '/mobile/wiki' do
    call env.merge("PATH_INFO" => "/mobile/wiki/item/all")
  end
  mobile_comment_routes("wiki")
end
