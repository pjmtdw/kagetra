# -*- coding: utf-8 -*-
module ResultExcelHelpers
  def send_excel(ev)
    mincho = "ＭＳ Ｐ明朝"
    default_height = 15.75

    content_type 'application/vnd.ms-excel'
    book = Spreadsheet::Workbook.new
    sheet = book.create_worksheet(name:"#{ev.date.year}-#{ev.name}")
    sheet.default_format = Spreadsheet::Format.new(
      shrink:true,
      font:Spreadsheet::Font.new(mincho,size:11))

    # 列の長さを決めるためにあらかじめ選手名，対戦相手の名前の最大長さを取得しておく
    # 団体戦の場合は (将順) って文字を入れるので少し大きめにする
    namelen = (15 * ev.result_users.map{|x|x.name.size}.max) + if ev.team_size == 1 then 0 else 40 end
    aitelen = (15 * ev.result_users.map{|x|x.games.map{|y|y.opponent_name}}.flatten.compact.map{|x|x.size}.max)
    [19,31,12,33,19,namelen,12,40,12,aitelen,200,19].each_with_index{|w,i|
      # ピクセルからSpredsheet内部のwidthに変換
      sheet.column(i).width = w / 7.0
    }

    num = 0
    inc_num = ->(num){
      row = sheet.row(num+1)
      row.height = default_height
      [num+1,row]
    }
    # 大会名
    row = sheet.row(num)
    row.height = 60.0
    row.default_format = Spreadsheet::Format.new(
      vertical_align: :center,
      horizontal_align: :center,
      text_wrap:true,
      shrink:false,
      font:Spreadsheet::Font.new(mincho,size:22))
    row[1] = ev.formal_name || ev.name
    sheet.merge_cells(num,1,num,10)

    # TODO: spreadsheetライブラリだと14.25(19px) 以下に設定できない
    num += 1
    sheet.row(num).height = 9.0

    (num,row) = inc_num.call(num)
    # 日付
    row[0] = ev.date.strftime("%Y年%m月%d日")
    sheet.merge_cells(num,0,num,5)
    
    # 各級の参加者数
    if ev.team_size == 1 then
      format = sheet.default_format.clone
      format.horizontal_align = :right
      row.set_format(6,format)
      row[6] = ev.result_classes.all(order:[:index.asc]).map{|c| if c.num_person.to_i > 0 then "#{c.class_name.sub(/級/,'')}:#{c.num_person}" end}.compact.join(" ")
      sheet.merge_cells(num,6,num,10)
    end

    (num,row) = inc_num.call(num)
    # 場所
    sheet.merge_cells(num,0,num,10)
    row[0] = "＠ #{ev.place}"

    num += 1
    sheet.row(num).height = 9.0

    classes = ev.result_classes.all(order:[:index.asc])
    if ev.team_size != 1 then
      teams = ContestTeam.all(contest_class:classes)
    end
    # 試合結果
    round = 1
    loop{
      if ev.team_size == 1 then
        games = ContestGame.all(contest_class:classes,round:round).group_by{|x|x.contest_class_id}
      else
        op_teams = ContestTeamOpponent.all(contest_team:teams,round:round)
        games = ContestGame.all(contest_team_opponent:op_teams).group_by{|x|x.contest_team_opponent_id}
      end
      break if games.empty?
      (num,row) = inc_num.call(num)
      row[2] = "#{round}回戦"
      sheet.merge_cells(num,2,num,10)
      chunks = if ev.team_size == 1 then classes else op_teams end
      chunks.each{|c|
        # TODO: 団体戦の同会対決の場合は負けた側を表示しない
        next unless games.has_key?(c.id)
        (num,row) = inc_num.call(num)
        theader = if ev.team_size == 1 then
                    round_name = c.round_name[round.to_s]
                    c.class_name + if round_name then " (#{round_name})" else "" end
                  else 
                    team = c.contest_team
                    cname = team.contest_class.class_name + if c.round_name then "(#{c.round_name})" else "" end
                    vs =  if c.kind == :single then
                            "(個人戦)"
                          else
                            "対 #{c.name}"
                          end
                   "#{cname}: #{team.name} #{vs}"
                 end
        row[3] = theader 
        sheet.merge_cells(num,3,num,10)
        
        wls = games[c.id].select{|x|[:win,:lose].include?(x.result)}
        gs = if ev.team_size == 1 then
               wls = wls.sort_by{|g|g.contest_user.win}.reverse
               # 同会対決の場合は負けた方は表示しない
               cusers = wls.map{|g|[g.contest_user.name,g.opponent_name]}
               wls.reject{|g|
                 g.result == :lose and cusers.include?([g.opponent_name,g.contest_user.name])
               }
             else
               wls.sort_by{|g|team.members.first(contest_user:g.contest_user).order_num}
             end
        gs.each{|x|
          (num,row) = inc_num.call(num)
          format = sheet.default_format.clone
          format.horizontal_align = :center
          format.bottom = :thin
          row.set_format(7,format)
          row[4] = case x.result
                   when :win then "○"
                   when :lose then "●"
                   end
          order_num = if ev.team_size == 1 then "" else " (#{team.members.first(contest_user:x.contest_user).order_num})" end
          belongs = if ev.team_size == 1 then
                      x.opponent_belongs
                    elsif c.kind == :single then
                      x.opponent_belongs + if x.opponent_order then "・#{x.opponent_order}" else "" end
                    else
                      x.opponent_order
                    end

          row[5] = x.contest_user.name + order_num
          row[7] = x.score_str
          row[9] = x.opponent_name
          row[10] = "(#{belongs})" if belongs

        }
        default_wins = games[c.id].select{|x|x.result == :default_win}.map{|x|
          x.contest_user.name
        }
        if not default_wins.empty? then
          max_row_length = 26
          buf = "不戦…"
          fusens = []
          default_wins.each_with_index{|x,i|
            s = x + if i != default_wins.size-1 then "、" else "" end
            tbuf = buf + s
            if tbuf.size > max_row_length then
              fusens << buf
              buf = "　　　" + s
            else
              buf = tbuf
            end
          }
          fusens << buf
          fusens.each{|b|
            (num,row) = inc_num.call(num)
            row[4] = b
            sheet.merge_cells(num,4,num,10)
          }
        end
      } 
      round += 1
    }

    # 入賞
    prizes = if ev.team_size == 1 then
      classes.map{|x|
        x.prizes.all(order:[:rank.asc]).map{|x|
          prize = x.prize
          name = x.contest_user.name
          if /\(.*\)/ =~ prize then
            name += $&
            prize = $` + $'
          end
          {klass:x.contest_class.class_name,prize:prize,name:name}
        }
      }.flatten
    else
      classes.map{|x|
        x.teams.all(order:[:rank.asc]).map{|x|
          prize = x.prize
          name = x.name
          next unless prize
          if /\(.*\)/ =~ prize then
            name += $&
            prize = $` + $'
          end
          {klass:x.contest_class.class_name,prize:prize,name:name}
        }
      }.flatten.compact
    end
    if not prizes.empty? then
      (num,row) = inc_num.call(num)
      (num,row) = inc_num.call(num)
      row[7] = if ev.team_size == 1 then "入賞者" else "順位" end
      sheet.merge_cells(num,7,num,8)
      (num,row) = inc_num.call(num)

      prizes.each{|p|
        (num,row) = inc_num.call(num)
        sheet.merge_cells(num,0,num,4)
        sheet.merge_cells(num,5,num,6)
        sheet.merge_cells(num,7,num,10)
        row.height = 31.5
        format = sheet.default_format.clone
        format.font = Spreadsheet::Font.new(mincho,size:16)
        format.horizontal_align = :right
        format.vertical_align = :center
        row.set_format(0,format)
        format = sheet.default_format.clone
        format.font = Spreadsheet::Font.new(mincho,size:16)
        format.horizontal_align = :center
        format.vertical_align = :center
        row.set_format(5,format)
        format = sheet.default_format.clone
        format.font = Spreadsheet::Font.new(mincho,size:20)
        format.vertical_align = :center
        row.set_format(7,format)
        row[0] = p[:klass]
        row[5] = p[:prize]
        row[7] = p[:name]
      }
    end


    # 標準出力に出力する
    sio = StringIO.new("","r+")
    book.write(sio)
    sio.string
  end
end
