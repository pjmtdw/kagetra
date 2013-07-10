#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

NUM_THREADS = 8

require './init'
require 'parallel'
require 'sqlite3'

def make_tasks
  # rake -j 16 -m とかで並列実行できるように rake で書く
  tasks = [:zokusei, :user, :login_log, :meibo,
    :bbs, :schedule, :shurui, :event, 
    :endtaikai, :event_comment, :wiki, :album]

  multitask :default => tasks

  tasks.each{|t|
    multitask t do
      send("import_#{t}".to_sym)
    end
  }

  multitask :user => :zokusei

  [:login_log,:meibo,:bbs,:schedule,:event,:endtaikai,:event_comment,:wiki,:album].each{|t|
    multitask t => :user
  }
  [:event,:endtaikai].each{|t|
    multitask t => :shurui
  }

  multitask :event_comment => [:event, :endtaikai]
end

GLOBAL_LOCK = Mutex.new
DMP = DiffMatchPatch.new

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

def guess_agg_attr(tbuf)
  r = tbuf.map{|x|
    if /^<!--(.*)-->/ =~ x then
      UserAttributeKey.first(UserAttributeKey.values.value => $1)
    end
  }.compact.group_by{|x|x}.map{|k,v|[v.size,k]}.sort_by{|c,x|c}.last || [1,UserAttributeKey.first(index:0)]
  r[1]
end

def import_zokusei
  puts "import_zokusei begin"
  k = UserAttributeKey.create(name:"全員", index: 0)
  k.values.create(value:"全員", index: 0)
  File.readlines(File.join(CONF_HAGAKURE_BASE,"txts","zokusei.cgi")).to_enum.with_index(1){|b,i|
    b.chomp!
    b.sjis!
    cols = b.split(/\t/)
    keys = cols[0].split(/<>/)
    verbose_name = keys[0]
    values = cols[1].split(/<>/)
    attr_key = UserAttributeKey.create(name:verbose_name, index: i)
    values.each_with_index{|v,ii|
      attr_key.values.create(value:v,index:ii)
    }
  }

end

def import_user
  puts "import_user begin"
  Parallel.each_with_index(File.readlines(File.join(CONF_HAGAKURE_BASE,"txts","namelist.cgi")),in_threads: NUM_THREADS){|code,index|
    next if index == 0
    code.chomp!
    File.readlines(File.join(CONF_HAGAKURE_BASE,"passdir","#{code}.cgi")).to_enum.with_index(1){|line,lineno|
      begin
        line.chomp!
        line.sjis!
        (uid,name,password_hash,login_num,last_login,user_info) = line.split("\t")
        last_login.sub!(/\*$/,"") if last_login
        (uid,auth) = uid.split("<>")
        (name,furigana,*zokusei) = name.split("+")
        (remote_host,user_agent,last_access) = user_info.split("<>") if user_info
        last_login = begin DateTime.parse(last_login) rescue nil end
        (n_total,n_monthbefore,n_yearbefore) = login_num.split("<>").map{|x|x.to_i} if login_num
        u = User.create(id: uid, name: name, furigana: furigana, show_new_from: last_login)
        if last_login
          u.login_latest = UserLoginLatest.create(user:u,remote_host:remote_host,user_agent:user_agent)
          u.login_latest.update!(updated_at:last_login)
        end
        if login_num and n_total and n_total > 0 then
          n_monthbefore = 0 if n_monthbefore.nil? 
          u.login_monthly.create(year:last_login.year,month:last_login.month,count:n_total-n_monthbefore)
        end
        puts name
        zokusei.each_with_index{|a,i|
          val = UserAttributeKey.first(index:i).values.first(index:a)
          u.attrs.create(value:val)
        }
      rescue DataMapper::SaveFailureError => e
        puts "Error at #{code} line #{lineno}"
        p e.resource.errors
        raise e
      end
    }
  }
end

def import_login_log
  files = Dir.glob(File.join(CONF_HAGAKURE_BASE,"passdir","ranking*.cgi"))
  Parallel.each(files, in_threads:NUM_THREADS){|fn|
    next unless /ranking(\d{4})(\d{2})\.cgi$/ =~ fn
    year = $1.to_i
    month = $2.to_i
    puts "y=#{year}, m=#{month}"
    File.readlines(fn)[1..-1].each{|line|
      line.chomp!
      (num,uid) = line.split(/<>/)
      user = User.get(uid.to_i)
      if user.nil? then
        puts "USER ID:#{uid} not found: ignoring login log"
        next
      end
      Kagetra::Utils.dm_debug(fn){
        UserLoginMonthly.update_or_create({user:user, year:year, month: month},{count:num.to_i})
      }
    }
  }
end

def import_bbs
  puts "import_bbs begin"
  num_to_line = {}
  Parallel.each(Dir.glob(File.join(CONF_HAGAKURE_BASE,"bbs","*.cgi")), in_threads: NUM_THREADS){|fn|
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
          user = User.get($1)
          name.sub!(pat,"")
        end
        item_props = {
          deleted: deleted,
          created_at: date,
          user_name: name,
          remote_host: host,
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
            item = thread.comments.create(item_props.merge(id: num, body: body))
            thread.first_item = item
            thread.save
            # use update! to avoid automatic setting by dm-timestamps
            item.update!(updated_at: date)
            thread.update!(updated_at: date)
            puts title
          else
            check_duplicate.call(num)
            body = others.join("\t").body_replace
            item = thread.comments.create(item_props.merge(id: num, body: body, thread: thread))
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
  puts "import_schedule begin"
  Parallel.each(Dir.glob(File.join(CONF_HAGAKURE_BASE,"scheduledir","*.cgi")), in_threads: NUM_THREADS){|fn|
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
          user = search_user_name(name)
          if user.nil? then
            raise Exception.new("no user named: '#{name}'")
          end
          item = ScheduleItem.create(
            owner: user,
            kind: kind,
            public: not_public != "1",
            emphasis: emphasis,
            name: title,
            date: date,
            start_at: start_at,
            end_at: end_at,
            place: place,
            description: if desc then desc.body_replace end,
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
  puts "import_shurui begin"
  fn = File.join(CONF_HAGAKURE_BASE,"txts","shurui.cgi")
  lines = File.readlines(fn)
  lines.to_enum.with_index(1){|line,lineno|
    line.chomp!
    line.sjis!
    (num,name,description) = line.split("\t")
    Kagetra::Utils.dm_debug("#{fn} line #{lineno}"){
      group = EventGroup.create(id:num, name:name, description:description)
    }
  }
end

def iskonpa2etype(iskonpa)
  case iskonpa
  when "-1" then :contest
  when "0","1" then  :etc
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
  puts "import_event begin"
  lines = File.readlines(File.join(CONF_HAGAKURE_BASE,"txts","taikailist.cgi"))[1..-1]
  Parallel.each(lines,in_threads:NUM_THREADS){|line|
    line.chomp!
    line.sjis!
    (taikainum,kaisaidate,iskonpa,kanrisha,koureitaikai) = line.split("\t")
    shurui = if koureitaikai.to_s.empty?.! then EventGroup.get(koureitaikai.to_i) end
    (kyear,kmon,kday,khour,kmin,kweekday) = kaisaidate.split('/')
    if kyear == "なし" then
      kaisaidate = nil
    else
      kaisaidate = Date.new(kyear.to_i,kmon.to_i,kday.to_i)
    end
    (tourokudate,kanrisha) = kanrisha.split('<>')
    etype = iskonpa2etype(iskonpa)
    kanrishas = kanrisha.split(',').map{|k| k.strip}
    tbuf = File.readlines(File.join(CONF_HAGAKURE_BASE,"taikai","#{taikainum}.cgi")).map{|x|
      x.chomp!
      x.sjis!
    }
    (taikainame,seisikimeishou,choices,kounin,teamnum,bikou,place) = parse_common(tbuf)
    puts taikainame
    (bikou_opt,simekiri,agg_attr,show_choice,fukalist,userchoice) = nil
    hide_result = {yes:false,no:false}
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
          k = UserAttributeKey.first(index:key.to_i)
          v = k.values.first(index:val.to_i)
        }.compact
      when /^\[KAIHI\](\d?)/
        agg_attr = UserAttributeKey.first(index:$1.to_i)
        bikou_opt = ''
        next unless agg_attr
        if nextline.to_s.empty?.! then
          xx = tbuf[lineno+2].split('&')
          zz = xx.each_with_index.map{|x,ii|
            next if x.empty?
            v = agg_attr.values.first(index:ii)
            if not v then raise Exception.new("no UserAttributeValue which has key:#{agg_attr.id} and index:#{ii-1} at taikainum:#{taikainum}") end
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
          when "0" then hide_result[typ] = true
          when "1" then hide_result[typ] = false
          when "2" then show_choice = false
          end
          ttss = m[1..-1].scan(/<!--(\d+)-->(.*?)(?=<!--\d+-->|$)/)
          next unless ttss
          ttss.map{|attr_index,zz|
            zz.split(/\t/).each_with_index.map{|mm,ci|
              mm.split(/ *, */).map{|ss|
                next if ss.empty?
                (name,date) = ss.split(/ *<> */).map{|x|x.strip}
                {
                  typ:typ,
                  date:DateTime.parse(date.sub(/\*/,"")),
                  name:name,
                  ci:ci,
                  attr_index:attr_index.to_i
                }
              }
            }
          }
        }.flatten.compact
      end
    }
    begin
      start_at = if khour.to_i == 0 && kmin.to_i == 0 then nil else Kagetra::HourMin.new(khour,kmin) end
      evt = Event.create(
        id: taikainum,
        name:taikainame,
        formal_name: seisikimeishou,
        official: kounin,
        kind:etype,
        team_size: teamnum,
        description: "#{bikou}\n#{bikou_opt}",
        deadline: simekiri,
        date: kaisaidate,
        created_at: DateTime.parse(tourokudate),
        place: place,
        event_group: shurui,
        hide_choice: ! show_choice,
        aggregate_attr: agg_attr,
        start_at: start_at
      )
      kanrishas.each{|k|
        user = search_user_name(k)
        if user.nil? then
          raise Exception.new("user name not found: #{k}")
        end
        evt.owners << user.id
      }
      fukalist.each{|k|
        evt.forbidden_attrs << k.id
      }
      evt.save
      if not choices.nil? then
        choices.each_with_index{|(kind,name),i|
          positive = kind==:yes
          if name.to_s.empty? then
            name = if positive then "参加する" else "参加しない" end
          end
          hr = hide_result[kind]
          evt.choices.create(name:name,positive: positive, index: i, hide_result: hr)
        }
      else
          # create default
          evt.choices.create(name:"参加する", positive:true, index: 0, hide_result: false)
          evt.choices.create(name:"参加しない", positive:false, index: 1, hide_result:true)
      end
      userchoice.each{|uc|
        puts "adding: user #{uc[:name]} to #{evt.name}"
        user = search_user_name(uc[:name])
        choice = if uc[:typ] == :yes then
                    evt.choices.first(positive:true,index:uc[:ci])
                 else
                    evt.choices.first(positive:false)
                 end
        if choice.nil? then
          raise Exception.new("choice is nil: user=#{user}, uc=#{uc.inspect}, evt=#{evt.inspect}")
        end
        av = agg_attr.values.first(index:uc[:attr_index])
        choice.user_choices.create(user:user, attr_value: av)
      }
    rescue DataMapper::SaveFailureError => e
      puts "Error at #{taikainame}"
      p e.resource.errors
      raise e
    end
  }
end

def get_user_or_add(evt,username)
  username.strip!
  begin
    u = User.first(name:username)
    GLOBAL_LOCK.synchronize{
      # first_or_create は thread safe ではないみたい
      ContestUser.first_or_create({name:username,user:u,event:evt}) 
    }
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
    op_team.games.create(
      type: :team,
      contest_user:user,
      result:result,
      score_str:maisuu,
      score_int:score_int,
      opponent_name:op_name,
      opponent_belongs:opponent_belongs,
      opponent_order:shojun,
    )
  }
  handle_match = lambda{|curl|
    ss = curl.split(/\t/)
    return if ss.empty?
    if ss.size == 1 then
      user = get_user_or_add(evt,ss[0])
      team_members[team] << user
      return
    end
    (name,prize) = ss[0..2]
    if name.to_s.empty? then
      return
    end
    user = get_user_or_add(evt,name)
    team_members[team] << user
    ss[2..-1].to_enum.with_index(1){|body,round|
      handle_single.call(user,round,body)
    }
    if prize.to_s.empty?.! then
      (pr,kpt) = prize.split(/<>/)
      kpt = if kpt.to_s.empty? then
        0
      else
        kpt.to_i
      end
      if pr.to_s.empty?.! then
        klass.prizes.create(contest_user:user,prize:pr,point:0,point_local:kpt)
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
      end
      team = klass.teams.create(name: team_name, prize: pr, rank: Kagetra::Utils.rank_from_prize(pr), promotion: promtype)
      team_members[team] = []
      puts "dantai result #{evt.name} of #{team_name}"
      handle_opponents.call(ss[2..-1])
    else
      if team then
        handle_match.call(curl)
      end
    end
  }
  team_members.each{|k,v|
    v.to_enum.with_index(1){|user,rank|
      team.members.create(order_num:rank,contest_user:user)
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
        type: :single,
        contest_user:user,
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
  handle_match = lambda{|curl,answercounter,klass|
    ss = curl.split(/\t/)
    return if ss.empty?
    if ss.size == 1 then
      if ss[0].to_s.empty? then
        return
      end
      choice = evt.choices.first(positive:true,index:answercounter)
      if choice.nil? then
        if answercounter == 0 then
          choice = evt.choices.create(positive:true,name:"参加する",index:0)
        else
          raise Exception.new("answercounter != 0 && choice does not exist")
        end
      end
      av = evt.aggregate_attr.values.first(value:klass.class_name)
      if av.nil? and evt.kind == :contest then
        rank = Kagetra::Utils.class_from_name(klass.class_name)
        if rank.nil?.! then
          evt.aggregate_attr.values.each{|x|
            r = Kagetra::Utils.class_from_name(x.value)
            if r == rank then
              av = x
              break
            end
          }
        end
      end
      if av.nil? then
        av = evt.aggregate_attr.values.first(index: 0)
        puts "WARNING: event='#{evt.name}' cannot guess attribute of '#{klass.class_name}', i will set it as '#{av.value}'."
      end
      name = ss[0]
      user = search_user_name(name)
      choice.user_choices.create(user:user,user_name:name,attr_value:av)
      return
    end
    (name,prize) = ss[0...2]
    if name.to_s.empty? then
      return
    end
    user = get_user_or_add(evt,name)
    puts "result of #{evt.name} user #{user.name}"
    ContestSingleUserClass.create(contest_user:user,contest_class:klass)
    ss[2..-1].to_enum.with_index(1){|body,round|
      handle_single.call(user,round,body)
    }
    if prize.to_s.empty?.! then
      (pr,pt,kpt) = prize.split(/<>/)
      pt ||= 0
      kpt ||= 0
      if pr.to_s.empty?.! then
        pt = if pt then pt.to_i else 0 end
        kpt = if kpt then kpt.to_i else 0 end
        promtype = nil
        if /\((.+)\)/ =~ pr then
          promtype = case $1
          when 'ダッシュ' then :dash
          when '昇級' then :rank_up
          end
        end
        klass.prizes.create(rank:Kagetra::Utils.rank_from_prize(pr),contest_user:user,prize:pr,promotion:promtype,point:pt,point_local:kpt)
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
        num_person = if num_person.to_s.empty? then nil else num_person.to_i end
        kl = Kagetra::Utils.class_from_name(klass_name)
        begin
          klass = evt.result_classes.create(index:order,class_rank:kl,class_name:klass_name,num_person:num_person)
        rescue Exception => e
          puts "ERROR in: #{evt.inspect} order:#{order}, class_rank:#{kl}, klass_name:#{klass_name}, num_person: #{num_person}"
          throw e
        end
        order += 1
      elsif klass
        handle_match.call(curl,answercounter,klass)
      end
    }
  end
end

def import_endtaikai
  puts "import_endtaikai begin"
  lines = File.readlines(File.join(CONF_HAGAKURE_BASE,"txts","endtaikailist.cgi"))
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
      kaisaidate = Date.new(kyear.to_i,kmon.to_i,kday.to_i)
    end
    shurui = if koureitaikai.to_s.empty?.! then EventGroup.get(koureitaikai.to_i) end
    (tourokudate,kanrisha) = kanrisha.split(/<>/)
    if tourokudate.nil? then
      tourokudate = "1975/01/01"
    end
    (taikainame,seisikimeishou) = taikainame.split(/<>/)
    tbuf = File.readlines(File.join(CONF_HAGAKURE_BASE,"resultdir/#{tnum}.cgi")).map{|x|
      x.chomp!
      x.sjis!
    }
    etype = iskonpa2etype(iskonpa)
    (taikainame,seisikimeishou,choices,kounin,teamnum,bikou,place) = parse_common(tbuf)
    puts "#{kaisaidate.year} - #{taikainame}"
    if invalid_kaisaidate then
      bikou += "\nDateInvaild: 日付は仮のもの．正しい日付は不明"
    end
    agg_attr = guess_agg_attr(tbuf)
    begin
      evt = Event.create(
                       id: tnum,
                       name: taikainame,
                       formal_name: seisikimeishou,
                       official: kounin,
                       kind: etype,
                       team_size: teamnum,
                       description: bikou,
                       date: kaisaidate,
                       created_at: DateTime.parse(tourokudate),
                       place: place,
                       event_group: shurui,
                       aggregate_attr: agg_attr,
                       start_at: Kagetra::HourMin.new(khour,kmin)
      )
      if choices then 
        choices.each_with_index{|(typ,name),i|
          positive = (typ == :yes)
          if name.to_s.empty? then
            name = if positive then "参加する" else "参加しない" end
          end
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
      if evt.team_size == 1 then
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

def import_event_comment 
  puts "import_event_comment begin"
  files = Dir.glob(File.join(CONF_HAGAKURE_BASE,"taikai","*-c.cgi"))
  Parallel.each(files,in_threads:NUM_THREADS){|fn|
    taikainum = if /^(\d+)-c.cgi$/ =~ File.basename(fn) then
      $1
    else
      raise Exception.new("invalid filename: #{fn}")
    end
    evt = Event.get(taikainum)
    if not evt then
      puts "WARNING: event with id='#{taikainum}' not found. ignoring comment file '#{fn}'"
      next
    end
    lines = File.readlines(fn)[1..-1]
    lines.to_enum.with_index(2){|line,lineno|
      begin
        line.chomp!
        line.sjis!
        next if line.empty?
        (created,user_name,user_host,body) = line.split(/<>/)
        user = search_user_name(user_name)
        evt.comments.create(created_at: DateTime.parse(created),
                            user: user,
                            user_name: user_name,
                            remote_host: user_host,
                            body: body.body_replace)
      rescue Exception => e
        puts "Error at file #{fn}:#{lineno}"
        raise e
      end
    }
  }
end

  
REVERSE_CHANGED = Hash[CONF_USERNAME_CHANGED.map{|k,v|[v,k]}]

def search_user_name(name)
  user = User.first(name:name)
  if user.nil? then
    names = [CONF_USERNAME_CHANGED[name],REVERSE_CHANGED[name]].compact
    if names.empty?.! then
      user = User.first(name:names)
    end
    puts "WARNING: search_user_name failed #{name}" if user.nil?
  end
  user
end

def import_meibo
  ((meta,_),*rest) = CSV.read(CONF_MEIBO_CSV,encoding:'UTF-8').zip(0..Float::INFINITY)
  MyConf.update_or_create({name: "addrbook_confirm_enc"},{value: {text:Kagetra::Utils.openssl_enc(G_ADDRBOOK_CONFIRM_STR,CONF_MEIBO_PASSWD)}})

  Parallel.each(rest,in_threads:NUM_THREADS){|line,lineno|
    res = Hash[meta.zip(line)]
    updated_at = DateTime.parse(res["更新日時"])
    res.delete("更新日時")
    name = res["名前"].gsub(/\s+/,'')
    user = search_user_name(name)
    if user.nil? then
      raise Exception.new("no user name: #{name}")
    end
    book = AddrBook.create(user:user, text: Kagetra::Utils.openssl_enc(res.to_json,CONF_MEIBO_PASSWD))
    book.update!(updated_at: updated_at)
  }
end

def import_album_stage1
  group_index = {}

  lines = File.readlines(File.join(CONF_HAGAKURE_BASE,"txts/album_subdirlist.cgi"))
  Parallel.each(lines,in_threads:NUM_THREADS){|line|
    line.chomp!
    line.sjis!
    (num,name,place,year,mon,day,comment,ids) = line.split(/\t/)
    puts name
    if ids.to_s.empty?.! then
      ids.split(/<>/).each_with_index{|x,i|
        k = x.sub!(',','-')
        group_index[k] = i 
      }
    end
    comment = if comment.to_s.empty? then
      nil
    else
      comment.body_replace
    end
    place = nil if place and place.empty?
    (fyear,tyear) = year.split(/<>/)
    (fmon,tmon) = mon.split(/<>/)
    (fday,tday) = day.split(/<>/)
    fdate = begin Date.new(fyear.to_i,fmon.to_i,fday.to_i) rescue nil end
    tdate = begin Date.new(tyear.to_i,tmon.to_i,tday.to_i) rescue nil end
    Kagetra::Utils.dm_debug(line){
      AlbumGroup.create(id:num.to_i,name:name,place:place,start_at:fdate,end_at:tdate,comment:comment)
    }
  }

  old_ids = {}
  # 関連写真があるのでまず最初にAlbumItemを作ってから後でupdateする
  Parallel.each(Dir.glob(File.join(CONF_HAGAKURE_BASE,"album","albumlist_*.cgi")), in_threads: NUM_THREADS){|fn|
    lines = File.readlines(fn)
    (dnum,dname) = lines[0].chomp.sub(/^\+/,"").split(/\t/)
    lines[1..-1].each{|line|
      line.chomp!
      line.sjis!
      (fnum,fname,group,_,_,_,_,year) = line.split(/\t/)
      puts "#{dnum}-#{fnum}"
      group = nil if group and group.empty?
      Kagetra::Utils.dm_debug(line){
        ag = if group.nil?.! then
          AlbumGroup.get(group)
        else
          if year.to_s.empty? then year = nil end
          # 年が整数値でないものはそういう名前のグループを作る
          if year.nil? or year =~ /^\d+$/ then
            GLOBAL_LOCK.synchronize{
              AlbumGroup.first_or_create({year:year,dummy:true})
            }
          else
            GLOBAL_LOCK.synchronize{
              AlbumGroup.first_or_create({name:year})
            }
          end
        end


        GLOBAL_LOCK.synchronize{
          key = "#{dnum}-#{fnum}"
          gi = group_index[key]
          item = ag.items.create(group_index: gi)
          if old_ids.has_key?(key) then
            raise Exception.new("duplicate old_id key for #{key}")
          else
            old_ids[key] = [item.id, "#{dname}/#{fname}"]
          end
        }
      }
    }
  }

  old_ids
end

def import_album_stage2(old_ids)
  Parallel.each(old_ids.values,in_threads:NUM_THREADS){|item_id,prefix|
    puts prefix
    Kagetra::Utils.dm_debug(prefix){
      if not File.exist?(File.join(CONF_HAGAKURE_BASE,"album/#{prefix}.cgi")) then
        next
      end
      lines = File.readlines(File.join(CONF_HAGAKURE_BASE,"album/#{prefix}.cgi"))
      item = AlbumItem.get(item_id)

      create = ->(item,klass,path){
        abs_path = File.join(CONF_HAGAKURE_BASE,"album",path)
        (format,width,height) = nil
        if File.exist?(abs_path) then
          begin
            img = Magick::Image::read(abs_path).first
            format = img.format
            width = img.columns
            height = img.rows
          rescue Exception => e
          end
        end
        klass.create(album_item:item,path:path,format:format,width:width,height:height)
      }
      item.photo = create.call(item,AlbumPhoto,"#{prefix}.jpg")
      item.thumb = create.call(item,AlbumThumbnail,"#{prefix}_SMALL.jpg")
      (title,year,mon,day,place,comment,width,height,subdir,keyword,owner) = nil
      daily_choose = true
      lines.each{|line|
        line.chomp!
        line.sjis!
        case line
        when %r(<title>(.*)</title>)
          title = $1
        when %r(<!year>(.*)<!/year>.*<!mon>(.*)<!/mon>.*<!day>(.*)<!/day>)
          (year,mon,day) = [$1,$2,$3]
        when %r(<!place>(.*)<!/place>)
          place = $1
        when %r(<!comment>(.*)<!/comment>)
          comment = $1
          Kagetra::Utils.dm_debug(prefix){
            import_comment(item,comment)
          }
        when %r(<!ruiji>(.*)<!/ruiji>)
          (dn,_,fn) = $1.split(/&:&/)
          o = old_ids["#{dn}-#{fn}"]
          if o.nil? then
            puts "WARNING: album item not found. skipped creating relation: '#{dn}-#{fn}'"
          else
            rid = o[0]
            AlbumRelation.create(source:item,target_id:rid)
          end
        when %r(<!uploadperson>(.*)<!/uploadperson>)
          person = $1
          owner = search_user_name(person)
          if owner.nil? then
            puts "WARNING: user name #{person} not found in user table. setting owner_id to NULL"
          end

        when %r(<!rating>(.*)<!/rating>)
          rating = $1.to_i
          if rating == 1 then
            daily_choose = false
          end
        when %r(<area.*?coords="(.*?)".*?alt="(.*?)">)
          (x,y,r) = $1.split(",").map{|x|x.to_i}
          n = $2
          if n.to_s.empty? then
            puts "WARNING: empty tag, ignoring '#{prefix}'"
          else
            item.tags.create(name:n,coord_x:x,coord_y:y,radius:r)
          end
        end
      }
      item.do_after_tag_updated
      day = begin Date.new(year.to_i,mon.to_i,day.to_i) rescue nil end
      item.update(name:title,place:place,date:day,owner:owner,daily_choose:daily_choose)
    }
  }
end

def import_comment(item,comment)
  log = comment_log(comment).reverse
  revision = 1
  if log.size >= 2 then
    patches = log[0...-1].zip(log[1..-1]).map{|cur,prev|
      patches = DMP.patch_make(cur[:comment],prev[:comment])
      {patch:DMP.patch_toText(patches), username:cur[:username], date:cur[:date]}
    }.reverse
    patches.each_with_index{|x,i|
      u = nil
      if x[:username].nil?.! then
        u = search_user_name(x[:username])
        if u.nil? then
          puts "WARNING: user name '#{x[:username]}' not found when creating album comment log of '#{item.name}'"
        end
      end
      # TODO: x[:date] が nil (最初のパッチ) の日時を設定する
      item.comment_logs.create(user:u,album_item:item,revision:i+1,patch:x[:patch],created_at:x[:date])
    }
    revision = patches.size
  end
  item.update(comment:log[0][:comment],comment_revision:revision)
end

def comment_log(comment)
  cs = comment.split(/\t/)
  comment = ""
  log = [{comment:""}]
  cs.each{|c|
    username = nil
    patch = nil
    editdate = nil
    if %r(^##<name>(.*?)</name><date>(.*?)</date>(.*)) =~ c then
      username = $1
      editdate = DateTime.parse($2)
      patch = $3.body_replace
      comment = mypatch(comment,patch)
    else
      comment = c.body_replace
    end
    log << {comment:comment,username:username,date:editdate}
  }
  log
end

def mypatch(comment,patch)
  lines = comment.lines.map{|x|x.chomp}
  patches = patch.lines.map{|x|x.chomp}
  output = []
  (-1..lines.size).each{|i|
    j = i + 1
    deletemode = false
    while p = patches.shift do
      case p
      when /^\-#{j},/
        deletemode = true
      when /^\+#{j},/
        if i >= 0 and not deletemode then
          output << lines[i]
        end
        output << $'
        deletemode = true
      when /^(\+|\-)(\d+),/
        if $2.to_i > j then
          patches.insert(0,p)
          break
        end
      end
    end
    if i >=0 and not deletemode
      output << lines[i]
    end
  }
  output.join("\n")
end

def import_album
  import_album_stage2(import_album_stage1)
end

def import_wiki
  Kagetra::Utils.dm_debug{
    db = SQLite3::Database.open CONF_MYTOMA_WIKI_FILE
    db.execute("select id,text,revision,keyword,exhibited,deleted from wiki_wikipage"){|id,text,revision,keyword,exhibited,deleted|
      WikiItem.create(id:id,deleted:deleted==1,public:exhibited==1,title:keyword,body:text,revision:revision)
    }
    db.execute("select id,object_id,revision,datetime,patch,user_id from wiki_markuppatch"){|id,object_id,revision,datetime,patch,user_id|
      next if patch.strip.to_s.empty?
      WikiItemLog.create(wiki_item_id:object_id,revision:revision,created_at:DateTime.parse(datetime),user_id:user_id,patch:patch)
    }
    db.execute("select page_id,uploaded_datetime,user_id,file,description,deleted from wiki_attachedfile"){|page_id,uploaded_datetime,user_id,file,description,deleted|
      base = File.basename(file).sub(/_\d+$/,"").gsub("-","/")
      orig_name = Base64.strict_decode64(base)
      abs_path = "../mytoma/storage/wiki/#{file}"
      size = if File.exist?(abs_path) then File.size(abs_path) else 0 end
      WikiAttachedFile.create(wiki_item_id:page_id,created_at:DateTime.parse(uploaded_datetime),owner_id:user_id,path:file,orig_name:orig_name,description:description,deleted:deleted,size:size)
    }
  }
end

#make_tasks

#import_zokusei
#import_user
#import_login_log
#import_meibo
#import_bbs
#import_schedule
#import_wiki
import_album
#import_shurui
#import_event
#import_endtaikai
#import_event_comment
