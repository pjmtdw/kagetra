# -*- coding: utf-8 -*-
class MainApp < Sinatra::Base
  MOBILE_RESULT_STRINGS = {
    win: "勝ち",
    lose: "負け",
    default_win: "不戦",
    now: "対戦中"
  }
  def mobile_result_string(s)
    str = MOBILE_RESULT_STRINGS[s.to_sym]
    case s.to_sym
    when :win
      "<b>#{str}</b>"
    when :lose
      "<font color='teal'>#{str}</font>"
    when :default_win
      "<font color='gray'>#{str}</font>"
    when :now
      str
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
    post "/edit_round/:id/:class_id/:round" do
      data = params.select_attr("round","round_name","class_id")
      results = []
      params.each{|k,v|
        next unless k.start_with?("result_")
        cuid = k.sub("result_","")
        r = {
          cuid: cuid,
          result: v
        }
        ["score_str","opponent_name","opponent_belongs","comment"].each{|x|
          r[x] = params[x+"_"+cuid]  
        }
        results << r
      }
      data[:results] = results
      call_api(:post,'/api/result/update_round',data)
      mobile_haml <<-'HEREDOC'
%div
  更新しました
%div
  %a(href='result/edit_start/#{params[:id]}') 戻る
      HEREDOC
    end

    post "/update_num_person/:id" do
      data = []
      params.each{|k,v|
        next unless k.start_with?("num_person_")
        class_id = k.sub("num_person_","")
        data << {
          class_id: class_id,
          num_person: v
        }
      }
      call_api(:post,"/api/result/num_person",{data:data})
      mobile_haml <<-'HEREDOC'
%div
  更新しました
%div
  %a(href='result/edit_start/#{params[:id]}') 戻る
      HEREDOC
    end

    post "/edit_prize/:id/:class_id" do
      prizes = []
      params.each{|k,v|
        next unless k.start_with?("prize_")
        cuid = k.sub("prize_","")
        prizes << {
          cuid:cuid,
          prize:v,
          point:params["point_#{cuid}"],
          point_local:params["point_local_#{cuid}"]
        }

      }
      call_api(:post,"/api/result/update_prize",{class_id:params[:class_id],prizes:prizes})
      mobile_haml <<-'HEREDOC'
%div
  更新しました
%div
  %a(href='result/edit_start/#{params[:id]}') 戻る
      HEREDOC
    end
    {
      "contest/:id" => :result,
      "edit_start/:id" => :result_edit_start_single,
      "edit_prize/:id/:class_id" => :result_edit_prize_single,
      "edit_round/:id/:class_id/:round" => :result_edit_round_single,
    }.each{|k,v|
      get "/#{k}" do
        @info = call_api(:get,"/api/result/contest/#{params[:id]}")
        @classes = @info["contest_classes"]
        mobile_haml v
      end
    }

  end
  get '/mobile/result' do
    call env.merge("PATH_INFO" => "/mobile/result/contest/latest")
  end
end
