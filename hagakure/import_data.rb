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

end

def import_user
  Parallel.each_with_index(File.readlines(File.join(HAGAKURE_BASE,"txts","namelist.cgi")),in_threads: NUM_THREADS){|code,index|
    next if index == 0
    code.chomp!
    File.readlines(File.join(HAGAKURE_BASE,"passdir","#{code}.cgi")).each_with_index{|line,lineno|
      begin
        line.chomp!
        line.sjis!
        (uid,name,password_hash,login_num,last_login,user_agent) = line.split("\t")
        (uid,auth) = uid.split("<>")
        (name,furigana,zokusei) = name.split("+")
        puts name
        User.create(id: uid, name: name, furigana: furigana)
      rescue DataMapper::SaveFailureError => e
        puts "Error at #{code} line #{lineno+1}"
        p e.resource.errors
        raise e
      end
    }
  }
end


def import_bbs
  Parallel.each(Dir.glob(File.join(HAGAKURE_BASE,"bbs","*.cgi")), in_threads: NUM_THREADS){|fn|
    File.readlines(fn).each_with_index{|line,lineno|
      line.chomp!
      line.sjis!
      title = ""
      is_public = false
      thread = nil
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
            is_public = ["1","on"].include?(is_public)
            thread = BbsThread.create(deleted: deleted, created_at: date, title: title, public: is_public)
            item = BbsItem.create(item_props.merge(id: num, body: body, bbs_thread: thread))
            thread.first_item = item
            thread.save
            # use update! to avoid automatic setting by dm-timestamps
            item.update!(updated_at: date)
            thread.update!(updated_at: date)
            puts title
          else
            body = others.join("\t").body_replace
            item = BbsItem.create(item_props.merge(id: num, body: body, bbs_thread: thread))
            item.update!(updated_at: date)
          end
        rescue DataMapper::SaveFailureError => e
          puts "Error at #{fn} line #{lineno+1} index #{i+1}"
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
    File.readlines(fn).each_with_index{|line,lineno|
      begin
        day = lineno + 1
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
        puts "Error at #{fn} line #{lineno+1}"
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
    EventGroup.create(id:num, name:name, description:description)
    SHURUI[num.to_i] = name
  }
end

def iskonpa2etype(iskonpa)
  case iskonpa
  when -1 then :contest
  when 0 then  :etc
  when 1 then  :practice
  when 2 then  :party
  else raise Exception.new("invalid type: #{iskonpa}")
  end
end

def parse_common(tbuf)
  choices = []
  tbuf.each_with_index{|curl,lineno|
    nextline = tbuf[lineno+1]
    case curl
    when "[NAME]"
      (taikainame,seisikimeishou) = nextline.split('<>')
    when "[ANSWER]"
      (yes,no,notyet) = nextline.split('/')
      yeses = yes.split('<>')
      choices = yeses.map{|y| ['YES',y]} + [['NO',no]]
    when /^\[BIKOU\]/
      (kounin,teamnum) = curl[7..-1].split('-')
      kounin = (kounin == '1')
      teamnum = teamnum.to_i
      bikou = nexline.body_replace
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
     shurui = SHURUI[koureitaikai.to_i]
     (kyear,kmon,kday,khour,kmin,kweekday) = kaisaidate.split('/')
     if kyear == "なし" then
       kaisaidate = nil
     else
       kaisaidate = Date.new(kyear.to_i,kmon.to_i,kday.to_i)
       kstart_at = HourMin.new(khour.to_i,kmin.to_i)
     end
     (tourokudate,kanrisha) = kanrisha.split('<>')
     etype = iskonpa2etype(iskonpa)
     kanrishas = kanrisha.split(',').map{|k| k.strip}
     tbuf = File.readlines(File.join(HAGAKURE_BASE,"txts","#{taikainum}.cgi")).map{|x|
       x.chomp!
       x.sjis!
     }
     (taikainame,seisikimeishou,choices,kounin,teamnum,bikou,place) = parse_common(tbuf)
     tbuf.each_with_index{|curl,lineno|
       nextline = tbuf[lineno+1]
       case curl
       when '[SIMEKIRI]'
        simekiri = nextline
        (syear,smon,sday,sweekday) = simekiri.split('/')
        simekiri = if syear == 'なし' then nil else Date.new(syear.to_i,smon.to_i,sday.to_i) end
       end
     }
  }
end

import_user
import_bbs
import_schedule
#import_shurui
#import_event
