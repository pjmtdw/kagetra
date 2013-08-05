# -*- coding: utf-8 -*-
class MainApp < Sinatra::Base
  namespace '/mobile/event' do
    get '/detail/:from/:id' do
      @res = call_api(:get,"/api/event/item/#{params[:id]}",{detail:true})
      mobile_haml :event_detail
    end
    get '/choose/:id' do
      @res = call_api(:put,"/api/event/choose/#{params[:id]}")
      
      mobile_haml <<-'HEREDOC'
%div
  「#{@res["event_name"]}」に登録完了 =&gt; #{@res["choice"]}
%div
  %a(href='event') [戻る]
      HEREDOC
    end
  end
  def mobile_event_symbol(kind,official)
    case kind
    when "contest"
      if official then "★" else "<font color='green'>■</font>" end
    when "party"
      "<font color='#FF6666'>●</font>"
    when "etc"
      "<font color='#187CB4'>◆</font>"
    end
  end
  def mobile_show_event_date(s)
    dt = Date.parse(s)
    today = Date.today
    templ = "%m月%d日"
    if dt.year != today.year
      templ = "%Y年" + templ
    end
    dt.strftime(templ)
  end
  get '/mobile/event' do
    @list = call_api(:get,"/api/event/list").sort_by{|x|x["date"] || "9999-12-31"}
    mobile_haml :event
  end
  get '/mobile/event_done' do
    qs = if params.has_key?("page") then {page:params[:page]} else {} end
    @info = call_api(:get,"/api/schedule/ev_done",qs)
    p @info
    mobile_haml :event_done
  end
  mobile_comment_routes("event")
end
