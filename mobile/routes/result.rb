# -*- coding: utf-8 -*-
class MainApp < Sinatra::Base
  def mobile_result_string(s)
    case s
    when "win"
      "<b>勝ち</b>"
    when "lose"
      "<font color='gray'>負け</gray>"
    when "default_win"
      "不戦"
    when "now"
      "対戦中"
    end
  end
  def mobile_show_opponent_belongs(g)
    return "" unless g["opponent_belongs"] or g["opponent_order"]
    order = case g["opponent_order"]
            when 1 then "主将"
            when 2 then "副将"
            else "#{g["opponent_order"]}将"
            end
    "(" + [g["opponent_belongs"],order].compact.join(" / ") + ")"
  end
  namespace '/mobile/result' do
    get '/contest/:id' do
      @info = call_api(:get,"/api/result/contest/#{params[:id]}")
      mobile_haml :result
    end
  end
  get '/mobile/result' do
    call env.merge("PATH_INFO" => "/mobile/result/contest/latest")
  end
end
