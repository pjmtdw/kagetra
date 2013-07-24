# -*- coding: utf-8 -*-
module ResultExcelHelpers
  def send_excel(ev)
    mincho = "ＭＳ Ｐ明朝"
    default_height = 15.75

    attachment "#{ev.date.strftime('%Y-%m-%d')}_#{ev.name}.xls"
    content_type 'application/vnd.ms-excel'
    book = Spreadsheet::Workbook.new
    sheet = book.create_worksheet(name:"#{ev.date.year}-#{ev.name}")
    sheet.default_format = Spreadsheet::Format.new(
      shrink:true,
      font:Spreadsheet::Font.new(mincho,size:11))

    # 列の長さを決めるためにあらかじめ選手名，対戦相手の名前の最大長さを取得しておく
    namelen = (45 * ev.result_users.map{|x|x.name.size}.max)/3
    aitelen = (45 * ev.result_classes.map{|x|x.single_games.map{|y|y.opponent_name}}.flatten.compact.map{|x|x.size}.max)/3
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
    format = sheet.default_format.clone
    format.horizontal_align = :right
    row.set_format(6,format)
    row[6] = ev.result_classes.all(order:[:index.asc]).map{|c| "#{c.class_name.sub(/級/,'')}:#{c.num_person}"}.join(" ")
    sheet.merge_cells(num,6,num,10)

    (num,row) = inc_num.call(num)
    # 場所
    sheet.merge_cells(num,0,num,10)
    row[0] = "＠ #{ev.place}"

    num += 1
    sheet.row(num).height = 9.0

    classes = ev.result_classes.all(order:[:index.asc])
    # 試合結果
    round = 1
    loop{
      games = ContestGame.all(contest_class:classes,round:round).group_by{|x|x.contest_class_id}
      break if games.empty?
      (num,row) = inc_num.call(num)
      row[2] = "#{round}回戦"
      sheet.merge_cells(num,2,num,10)
      classes.each{|c|
        next unless games.has_key?(c.id)
        (num,row) = inc_num.call(num)
        round_name = c.round_name[round.to_s]
        row[3] = c.class_name + if round_name then " (#{round_name})" else "" end
        sheet.merge_cells(num,3,num,10)
        games[c.id].select{|x|[:win,:lose].include?(x.result)}.each{|x|
          (num,row) = inc_num.call(num)
          format = sheet.default_format.clone
          format.horizontal_align = :center
          format.bottom = :thin
          row.set_format(7,format)
          row[4] = case x.result
                   when :win then "○"
                   when :lose then "●"
                   end
          row[5] = x.contest_user.name
          row[7] = x.score_str
          row[9] = x.opponent_name
          row[10] = "(#{x.opponent_belongs})" if x.opponent_belongs

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
    prizes = classes.map{|x|
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
    if not prizes.empty? then
      (num,row) = inc_num.call(num)
      (num,row) = inc_num.call(num)
      row[7] = "入賞者"
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
