#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

HAGAKURE_BASE="/home/maho/hagakure/subdomains/hagakure/httpdocs"
NUM_THREADS = 8

require './init'
require 'nkf'
require 'parallel'

SHURUI = {}

class String
  def sjis!
    self.replace NKF.nkf("-Sw",self)
  end
  def body_replace
    self.gsub("<br>","\n")
      .gsub("&gt;",">")
      .gsub("&lt;","<")
      .gsub("&amp;","&")
      .gsub("&quot;","'")
      .gsub("&apos;","`")
  end
end

def import_zokusei
  File.readlines(File.join(HAGAKURE_BASE,"txts","zokusei.cgi")).each_with_index{|b,i|
    b.chomp!
    b.sjis!
    cols = b.split(/\t/)
    keys = cols[0].split(/<>/)
    verbose_name = keys[0]
    values = cols[1].split(/<>/)
    attr_key = UserAttributeKey.create(name:verbose_name, index: i)
    values.each_with_index{|v,ii|
      UserAttributeValue.create(user_attribute_key:attr_key,value:v,index:ii)
    }
  }

end

def import_user
  Parallel.each_with_index(File.readlines(File.join(HAGAKURE_BASE,"txts","namelist.cgi")),in_threads: NUM_THREADS){|code,index|
    next if index == 0
    code.chomp!
    File.readlines(File.join(HAGAKURE_BASE,"passdir","#{code}.cgi")).to_enum.with_index(1){|line,lineno|
      begin
        line.chomp!
        line.sjis!
        (uid,name,password_hash,login_num,last_login,user_agent) = line.split("\t")
        (uid,auth) = uid.split("<>")
        (name,furigana,zokusei) = name.split("+")
        puts name
        User.create(id: uid, name: name, furigana: furigana)
      rescue DataMapper::SaveFailureError => e
        puts "Error at #{code} line #{lineno}"
        p e.resource.errors
        raise e
      end
    }
  }
end


def import_bbs
  num_to_line = {}
  Parallel.each(Dir.glob(File.join(HAGAKURE_BASE,"bbs","*.cgi")), in_threads: NUM_THREADS){|fn|
    File.readlines(fn).to_enum.with_index(1){|line,lineno|
      line.chomp!
      line.sjis!
      title = ""
      is_public = false
      thread = nil

      check_duplicate = lambda{|num|
        cur = "#{fn} #{lineno}"
        if num_to_line.has_key?(num) then
          raise Exception.new("id duplicate: #{num} in #{cur} and #{num_to_line[num]}")
        end
        num_to_line[num] = cur
      }

      # there is some data which includes "\t" in body which was created when hagakure was immature
      # thus, we cannot simply split by "\t\t"
      line.scan(/((\t|^)\d+(<>(\d|on)?)?\t\d\t.+?)((?=\t\d+(<>)?\t)|$)/).each_with_index{|kakiko,i|
        kakiko = kakiko[0].sub(/^\t/,"")
        (num,not_deleted,name,host,date,*others) = kakiko.split("\t")
        (host,ip) = host.split(/<>/)
        date = DateTime.parse(date)
        deleted = (not_deleted == "0")
        pat = /<!--ID:(\d+)-->$/
        user = nil
        if pat =~ name then
          user = User.first(id: $1)
          name.sub!(pat,"")
        end
        item_props = {
          deleted: deleted,
          created_at: date,
          user_name: name,
          user_host: host,
          user: user
        }
        begin
          if i == 0 then
            title = others[0] || ""
            body = (others[1..-1] || []).join("\t").body_replace
            (num,is_public) = num.split("<>")
            check_duplicate.call(num)
            is_public = ["1","on"].include?(is_public)
            thread = BbsThread.create(deleted: deleted, created_at: date, title: title, public: is_public)
            item = thread.items.create(item_props.merge(id: num, body: body))
            thread.first_item = item
            thread.save
            # use update! to avoid automatic setting by dm-timestamps
            item.update!(updated_at: date)
            thread.update!(updated_at: date)
            puts title
          else
            check_duplicate.call(num)
            body = others.join("\t").body_replace
            item = thread.items.create(item_props.merge(id: num, body: body, bbs_thread: thread))
            item.update!(updated_at: date)
          end
        rescue DataMapper::SaveFailureError => e
          puts "Error at #{fn} line #{lineno} index #{i+1}"
          p e.resource.errors
          raise e
        end
      }
    }
  }
end

def import_schedule
  Parallel.each(Dir.glob(File.join(HAGAKURE_BASE,"scheduledir","*.cgi")), in_threads: NUM_THREADS){|fn|
    base = File.basename(fn)
    raise Exception.new("bad schedule filename: #{base}") unless /^(\d+)_(\d+).cgi$/ =~ base
    year = $1.to_i
    mon = $2.to_i
    File.readlines(fn).to_enum.with_index(1){|line,lineno|
      begin
        day = lineno
        line.chomp!
        line.sjis!
        (day_info,*others) = line.split(/<&&>/)
        others.each{|oth|
          (kind,wdate,name,title,place,start_at,end_at,desc) = oth.split(/\t/)
          (title,not_public) = title.split(/<>/) if title
          (place,emphasis_place) = place.split(/<>/) if place
          (start_at,emphasis_start) = start_at.split(/<>/) if start_at
          (end_at,emphasis_end) = end_at.split(/<>/) if end_at
          start_at = nil if start_at && start_at.empty?
          end_at = nil if end_at && end_at.empty?

          puts "#{kind} - #{title}"
          kind = case kind
                 when "1"
                   :practice
                 when "2"
                   :party
                 else
                   :etc
                 end
          emphasis = []
          emphasis << :place if emphasis_place == "1"
          emphasis << :start_at if emphasis_start == "1"
          emphasis << :end_at if emphasis_end == "1"

          date = Date.new(year,mon,day)
          created_at = DateTime.parse(wdate)
          user = User.first(name: name)
          if user.nil? then
            user = User.first(name: CONF_USERNAME_CHANGED[name])
            if user.nil? then
              raise Exception.new("no user named: '#{name}'")
            end
          end
          item = ScheduleItem.create(
            user: user,
            kind: kind,
            public: not_public != "1",
            emphasis: emphasis,
            title: title,
            date: date,
            start_at: start_at,
            end_at: end_at,
            place: place,
            description: desc,
            created_at: created_at
          )
          item.update!(updated_at: created_at)
           
        }
        if day_info then
          (holiday,day_info) = day_info.split(/\t/)
          is_holiday = holiday == "1"
          day_info = if day_info then
            day_info.split(/<br>/)
          else
            []
          end
          if is_holiday or day_info.empty?.! then
            date = Date.new(year,mon,day)
            ScheduleDateInfo.create(
              names: day_info,
              holiday: is_holiday,
              date: date
            )
            puts "#{date} => #{is_holiday} #{day_info}"
          end
        end
      rescue DataMapper::SaveFailureError => e
        puts "Error at #{fn} line #{lineno}"
        p e.resource.errors
        raise e
      end
    }
  }
end

def import_shurui
  lines = File.readlines(File.join(HAGAKURE_BASE,"txts","shurui.cgi"))
  lines.each{|line|
    line.chomp!
    line.sjis!
    (num,name,description) = line.split("\t")
    group = EventGroup.create(id:num, name:name, description:description)
    SHURUI[num.to_i] = group
  }
end

def iskonpa2etype(iskonpa)
  case iskonpa
  when "-1" then :contest
  when "0" then  :etc
  when "1" then  :practice
  when "2" then  :party
  else raise Exception.new("invalid type: #{iskonpa}")
  end
end

def parse_common(tbuf)
  choices = []
  (taikainame,seisikimeishou,choices,kounin,teamnum,bikou,place) = nil
  tbuf.each_with_index{|curl,lineno|
    nextline = tbuf[lineno+1]
    case curl
    when "[NAME]"
      (taikainame,seisikimeishou) = nextline.split('<>')
    when "[ANSWER]"
      (yes,no,notyet) = nextline.split('/')
      yeses = yes && yes.split('<>')
      choices = yeses && yeses.map{|y| [:yes,y]} + [[:no,no]]
    when /^\[BIKOU\]/
      (kounin,teamnum) = curl[7..-1].split('-')
      kounin = (kounin == '1')
      teamnum = teamnum.to_i
      bikou = nextline.body_replace
    when "[PLACE]"
      place = nextline
    end
  }
  [taikainame,seisikimeishou,choices,kounin,teamnum,bikou,place]
end

def import_event
  lines = File.readlines(File.join(HAGAKURE_BASE,"txts","taikailist.cgi"))[1..-1]
  if SHURUI.empty? then
    raise Exception.new("import_shurui not executed")
  end
  Parallel.each(lines,in_threads:NUM_THREADS){|line|
    line.chomp!
    line.sjis!
    (taikainum,kaisaidate,iskonpa,kanrisha,koureitaikai) = line.split("\t")
    shurui = if koureitaikai.to_s.empty?.! then SHURUI[koureitaikai.to_i] end
    (kyear,kmon,kday,khour,kmin,kweekday) = kaisaidate.split('/')
    if kyear == "なし" then
      kaisaidate = nil
    else
      kaisaidate = Date.new(kyear.to_i,kmon.to_i,kday.to_i)
      kstart_at = Kagetra::HourMin.new(khour.to_i,kmin.to_i)
    end
    (tourokudate,kanrisha) = kanrisha.split('<>')
    etype = iskonpa2etype(iskonpa)
    kanrishas = kanrisha.split(',').map{|k| k.strip}
    tbuf = File.readlines(File.join(HAGAKURE_BASE,"taikai","#{taikainum}.cgi")).map{|x|
      x.chomp!
      x.sjis!
    }
    (taikainame,seisikimeishou,choices,kounin,teamnum,bikou,place) = parse_common(tbuf)
    (bikou_opt,simekiri,agg_attr,show_choice,fukalist,userchoice) = nil
    tbuf.each_with_index{|curl,lineno|
      nextline = tbuf[lineno+1]
      case curl
      when '[SIMEKIRI]'
       simekiri = nextline
       (syear,smon,sday,sweekday) = simekiri.split('/')
       simekiri = if syear == 'なし' then nil else Date.new(syear.to_i,smon.to_i,sday.to_i) end
      when '[FUKA]'
        fukas = nextline.split('#')
        fukalist = fukas.map{|f|
          next if f.empty?
          (key,val) = f.split('.')
          k = UserAttributeKey.first(index:key.to_i-1)
          v = UserAttributeValue.first(user_attribute_key:k,index:val.to_i)
        }.compact
      when /^\[KAIHI\](\d?)/
        agg_attr = UserAttributeKey.first(index:$1.to_i-1)
        bikou_opt = ''
        next unless agg_attr
        if nextline.to_s.empty?.! then
          xx = tbuf[lineno+2].split('&')
          zz = xx.each_with_index.map{|x,ii|
            next if x.empty?
            v = UserAttributeValue.first(user_attribute_key:agg_attr,index:ii)
            if not v then raise Exception.new("no UserAttributeValue which has user_attribute_key:#{agg_attr.id} and index:#{ii-1} at taikainum:#{taikainum}") end
            v.value + x
          }.compact
          if zz.empty?.! then
            bikou_opt = nextline + ": " + zz.join(", ")
          end
        end
      when /^\[SANKA\](\d?)/
        revised = $1 == '1'
        member_yes= nextline
        member_no = tbuf[lineno+2]
        show_choice = true
        userchoice = [[:yes,member_yes],[:no,member_no]].map{|typ,m|
          case m[0]
          when 1 then show = true
          when 2 then show_choice = false
          end
          tts = m[1..-1].split(/<!--[0-9]-->/)
          ttss = tts[1..-1]
          next unless ttss
          ttss.map{|zz|
            zz.split(/\t/).each_with_index.map{|mm,ci|
              mm.split(/ *, */).map{|ss|
                next if ss.empty?
                (name,date) = ss.split(/ *<> */).map{|x|x.strip}
                {
                  typ:typ,
                  date:DateTime.parse(date.sub(/\*/,"")),
                  name:name,
                  ci:ci
                }
              }
            }
          }
        }.flatten.compact
      end
    }
    begin
      evt = Event.create(
        name:taikainame,
        formal_name: seisikimeishou,
        official: kounin,
        kind:etype,
        num_teams: teamnum,
        description: "#{bikou}\n#{bikou_opt}",
        deadline: simekiri,
        date: kaisaidate,
        created_at: DateTime.parse(tourokudate),
        place: place,
        event_group: shurui,
        show_choice: show_choice,
        aggregate_attr: agg_attr)
      kanrishas.each{|k|
        user = User.first(name:k)
        if user.nil? then
          raise Exception.new("user name not found: #{name}")
        end
        evt.owners << user
      }
      evt.owners.save
      fukalist.each{|k|
        evt.forbidden_attrs << k
      }
      evt.forbidden_attrs.save
      if not choices.nil? then
        choices.each_with_index{|(kind,name),i|
          evt.choices.create(name:name,positive: kind==:yes, index: i)
        }
      else
          # create default
          evt.choices.create(positive:true, index: 0)
          evt.choices.create(positive:false, index: 1)
      end
      userchoice.each{|uc|
        user = User.first(name:uc[:name])
        choice = if uc[:typ] == :yes then
                    EventChoice.first(event:evt,positive:true,index:uc[:ci])
                 else
                    EventChoice.first(event:evt,positive:false)
                 end
        if choice.nil? then
          raise Exception.new("choice is nil: user=#{user}, uc=#{uc.inspect}, evt=#{evt.inspect}")
        end
        choice.users << user
        choice.users.save
      }
    rescue DataMapper::SaveFailureError => e
      puts "Error at #{taikainame}"
      p e.resource.errors
      raise e
    end
  }
end

def get_user_or_add(username)
  username.strip!
  begin
    user = UserBase.first(name:username) || GuestUser.create(name:username)
  rescue DataMapper::SaveFailureError => e
    p e.resource.errors
    raise e
  end
end

def import_contest_result_dantai(evt,sankas)
  klass = nil
  team = nil
  team_members = {}
  handle_single = lambda{|user,round,body|
    if body.to_s.empty? then
      return
    end
    op_team = team.opponents.first(round:round)
    (result,maisuu,op_name,shojun,n) = body.split(/<>/)
    if result.to_s.empty? then
      raise Exception.new("something wrong with: event: #{evt.inspect} body:#{body}")
    end
    n ||= 0
    if op_team.kind == :single then
      (shojun,opponent_belongs) = shojun.split(/&&/)
    else
      opponent_belongs = nil
    end
    shojun = if shojun.to_s.empty?.! then shojun.to_i end
    result = case result
              when 'WIN','LOSE','NOW'
                result.downcase.to_sym
              when 'FUSEN'
                :default_win
              else
                raise Exception("unknwon result: #{result}")
              end
    score_int = Kagetra::Utils.eval_score_char(maisuu)
    op_team.games.create(user_name:user.name,user:user,result:result,score_str:maisuu,score_int:score_int,opponent_name:op_name,opponent_belongs:opponent_belongs,opponent_order:shojun)
  }
  handle_match = lambda{|curl|
    ss = curl.split(/\t/)
    return if ss.empty?
    if ss.size == 1 then
      user = get_user_or_add(ss[0])
      team_members[team] << user
      return
    end
    (name,prize) = ss[0..2]
    if name.to_s.empty? then
      return
    end
    user = get_user_or_add(name)
    team_members[team] << user
    ss[2..-1].to_enum.with_index(1){|body,round|
      handle_single.call(user,round,body)
    }
    if prize then
      (pr,kpt) = prize.split(/<>/)
      kpt = if kpt.to_s.empty? then
        0
      else
        kpt.to_i
      end
      if pr.nil?.! then
        klass.prizes.create(user:user,prize:pr,point:0,point_local:kpt)
      end
    end
  }
  handle_opponents = lambda{|tbuf|
    return if tbuf.nil?
    tbuf.to_enum.with_index(1){|b,round|
      (kaisen,op_team) = b.split(/<>/)
      kaisen = nil if kaisen == '#{round}回戦'
      if op_team == "_KOJIN" then
        op_team = nil
        typ = :single
      else
        typ = :team
      end
      opponent = team.opponents.create(round:round,round_name:kaisen,kind:typ,name:op_team)
    }
  }
  order = 0
  sankas.each{|curl|
    next if curl.to_s.empty? || curl.start_with?("#")
    case curl
    when /^<!--(.*)-->/
      klass_name = $1
      kl = Kagetra::Utils.class_from_name(klass_name)
      klass = evt.result_classes.create(index:order,class_rank:kl,class_name:klass_name)
      order += 1
    when /^\(\((.*)\)\)/
      team_name = $1
      if klass.nil? then
        raise Exception.new("no class for team: #{team_name}")
      end
      ss = curl.split(/\t/)
      pr = ss[1]
      if pr
        pr.sub!('）',')')
        pr.sub!('（','(')
      end
      promtype = nil
      if /\((.+)\)/ =~ pr then
        prom = $1
        promtype =  case prom
                      when "陥落" then :rank_down
                      when "昇級" then :rank_up
                    end
        if promtype then
          pr = $` + $'
        end
      end
      team = klass.teams.create(name: team_name, prize: pr, rank: Kagetra::Utils.rank_from_prize(pr), promotion: promtype)
      team_members[team] = []
      handle_opponents.call(ss[2..-1])
    else
      if team then
        handle_match.call(curl)
      end
    end
  }
  team_members.each{|k,v|
    v.to_enum.with_index(1){|user,rank|
      team.members.create(order_num:rank,user:user)
    }
  }
end

def import_contest_result_kojin(evt,sankas)
  klass = nil
  handle_single = lambda{|user,round,body|
    return if body.to_s.empty?
    (kaisen,result,maisuu,op_name,op_kai,comment) = body.split(/<>/)
    kaisen = Kagetra::Utils.zenkaku_to_hankaku(kaisen)
    if kaisen != "#{round}回戦" then
      klass.round_name ||= {}
      klass.round_name[round] = kaisen
      klass.save()
    end
    result = case result
             when "WIN" then :win
             when "LOSE" then :lose
             when "NOW" then :now
             when "FUSEN" then :default_win
             else raise Exception.new("unknown result: #{result}")
             end
    score_int = if maisuu then Kagetra::Utils.eval_score_char(maisuu) end
    begin
      klass.single_games.create(
        user_name:user.name,
        user:user,
        result:result,
        score_str: maisuu,
        score_int: score_int,
        opponent_name: op_name,
        opponent_belongs: op_kai,
        comment: comment,
        round: round)
    rescue DataMapper::SaveFailureError => e
      puts "Error at #{evt} #{user} #{round} #{body}"
      p e.resource.errors
      raise e
    end
  }
  handle_match = lambda{|curl,answercounter|
    ss = curl.split(/\t/)
    return if ss.empty?
    if ss.size == 1 then
      if ss[0].to_s.empty? then
        return
      end
      user = get_user_or_add(ss[0])
      choice = evt.choices.first(positive:true,index:answercounter)
      if choice.nil? then
        if answercounter == 0 then
          evt.choices.create(positive:true,name:"参加する",index:0)
        else
          raise Exception.new("answercounter != 0 && choice does not exist")
        end
      end
      evt.choices.users << user
      evt.choices.users.save
      return
    end
    (name,prize) = ss[0...2]
    if name.to_s.empty? then
      return
    end
    user = get_user_or_add(name)
    ContestSingleUserClass.create(user:user,contest_class:klass)
    ss[2..-1].to_enum.with_index(1){|body,round|
      handle_single.call(user,round,body)
    }
    if prize then
      (pr,pt,kpt) = prize.split(/<>/)
      pt ||= 0
      kpt ||= 0
      if pr then
        pt = if pt then pt.to_i else 0 end
        kpt = if kpt then kpt.to_i else 0 end
        promtype = nil
        if /\((.+)\)/ =~ pr then
          promtype = case $1
          when 'ダッシュ' then :dash
          when '昇級' then :rank_up
          end
          if promtype then
            pr = $` + $'
          end
        end
        klass.prizes.create(rank:Kagetra::Utils.rank_from_prize(pr),user:user,prize:pr,promotion:promtype,point:pt,point_local:kpt)
      end
    end
  }
  answercounter = 0
  order = 0
  if sankas then
    sankas.each_with_index{|curl,lineno|
      next if curl.nil?
      if curl == '##ASNWERKUGIRI##' then
        answercounter+=1
        next
      elsif curl.start_with?("#")
        next
      end
      if /^<!--(.*)-->\s*(\d*)/ =~ curl then
        answercounter = 0
        klass_name = $1
        num_person = $2
        num_person = if num_person == "" then nil else num_person.to_i end
        kl = Kagetra::Utils.class_from_name(klass_name)
        klass = evt.result_classes.create(index:order,class_rank:kl,class_name:klass_name,num_person:num_person)
        order += 1
      elsif klass
        handle_match.call(curl,answercounter)
      end
    }
  end
end

def import_endtaikai
  lines = File.readlines(File.join(HAGAKURE_BASE,"txts","endtaikailist.cgi"))
  if SHURUI.empty? then
    raise Exception.new("import_shurui not executed")
  end
  Parallel.each(lines,in_threads:NUM_THREADS){|line|
    line.chomp!
    line.sjis!
    (tnum,kaisaidate,iskonpa,kanrisha,taikainame,koureitaikai) = line.split(/\t/)
    (kyear,kmon,kday,khour,kmin,kweekday) = kaisaidate.split(/\//)
    invalid_kaisaidate = false
    if kyear == "なし" then
      kaisaidate = nil
    else
      if khour.to_s.empty? then
        khour = 0
      end
      if kmin.to_s.empty? then
        kmin = 0
      end
      if kday.to_s.empty? then
        invalid_kaisaidate = true
        kday = 1
      end
      kaisaidate = DateTime.new(kyear.to_i,kmon.to_i,kday.to_i,khour.to_i,kmin.to_i)
    end
    shurui = if koureitaikai.to_s.empty?.! then SHURUI[koureitaikai.to_i] end
    (tourokudate,kanrisha) = kanrisha.split(/<>/)
    if tourokudate.nil? then
      tourokudate = "1975/01/01"
    end
    (taikainame,seisikimeishou) = taikainame.split(/<>/)
    tbuf = File.readlines(File.join(HAGAKURE_BASE,"resultdir/#{tnum}.cgi")).map{|x|
      x.chomp!
      x.sjis!
    }
    etype = iskonpa2etype(iskonpa)
    (taikainame,seisikimeishou,choices,kounin,teamnum,bikou,place) = parse_common(tbuf)
    if invalid_kaisaidate then
      bikou += "\nDateInvaild: 日付は仮のもの．正しい日付は不明"
    end
    begin
      evt = Event.create(name: taikainame,
                       formal_name: seisikimeishou,
                       official: kounin,
                       kind: etype,
                       num_teams: teamnum,
                       description: bikou,
                       date: kaisaidate,
                       created_at: DateTime.parse(tourokudate),
                       place: place,
                       event_group: shurui)
      if choices then 
        choices.each_with_index{|(typ,name),i|
          positive = (typ == :yes)
          evt.choices.create(name:name,positive:positive,index:i)
       }
      end
      sankas = nil
      tbuf.to_enum.with_index(1){|b,i|
        if b.start_with?("[SANKA]") then
          sankas = tbuf[i..-1]
          break
        end
      }
      if evt.num_teams == 1 then
        import_contest_result_kojin(evt,sankas)
      else
        import_contest_result_dantai(evt,sankas)
      end
    rescue DataMapper::SaveFailureError => e
      puts "Error at #{taikainame}"
      p e.resource.errors
      raise e
    end

  }
end

import_zokusei
import_user
import_bbs
import_schedule
import_shurui
import_event
import_endtaikai
