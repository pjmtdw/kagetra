# -*- coding: utf-8 -*-

class ContestClass < Sequel::Model(:contest_classes)
  many_to_one :event
  serialize_attributes Kagetra::serialize_enum([:a,:b,:c,:d,:e,:f,:g]), :class_rank
  serialized_attr_accessor :class_rank__a

  plugin :serialization, :json, :round_name
  set_default_values_custom :round_name, "{}"

  one_to_many :single_games, class:'ContestSingleGame' # 試合結果(個人戦)
  one_to_many :prizes, class:'ContestPrize'
  one_to_many :teams, class:'ContestTeam' # 参加チーム(団体戦)
  one_to_many :users, class:'ContestUser'
  def before_save
    ev = self.event
    self.class_rank = if ev.official and ev.team_size == 1 then
                        # 公認大会でAからGの文字で始まっていないものは全てA級とみなす
                        Kagetra::Utils.class_from_name(self.class_name) || :a
                      end
    super
  end
end

class ContestUser < Sequel::Model(:contest_users)
  add_input_transformer_custom(:name){|v| v && v.gsub(/\s+/,"")}
  serialize_attributes Kagetra::serialize_enum([:a,:b,:c,:d,:e,:f,:g]), :class_rank
  many_to_one :user
  many_to_one :event
  many_to_one :contest_class

  one_to_one :prize, class:'ContestPrize'
  one_to_many :games, class:'ContestGame'

  def before_save
    self.class_rank = self.contest_class.class_rank
    super
  end
  
  def update_participant_count
    ev = self.event
    ev.update(participant_count:ev.result_users_dataset.count)
  end

  def after_create
    super
    update_participant_count
  end
  def after_destroy
    super
    update_participant_count
  end
end

class ContestResultCache < Sequel::Model(:contest_result_caches)
  many_to_one :event
  plugin :serialization, :json, :prizes
  set_default_values_custom :prizes,"[]"
  def update_prizes
    ev = self.event
    prz = ev.result_classes_dataset.order(Sequel.asc(:index)).map{|c|
      r = if ev.team_size > 1 then
            c.teams.map{|t|
              if t.prize.nil?.! then
                t.select_attr(:name,:prize).merge({type: :team,class_name:c.class_name})
              end
            }.compact
          else [] end
      r + c.prizes_dataset.order(Sequel.asc(:rank)).map{|x|
        p = x.select_attr(:prize,:point,:point_local,:promotion)
        cuser = x.contest_user
        p.merge!({type: :person,name:cuser.name,user_id:cuser.user_id,class_name:c.class_name})
      }
    }.flatten
    self.update(prizes:prz)
  end
  def update_winlose
    x = self.event.result_users_dataset.select(
      Sequel.function(:coalesce,Sequel.function(:sum,:win),0).as("sum_win"),Sequel.function(:coalesce,Sequel.function(:sum,:lose),0).as("sum_lose")
    ).first
    self.update(win:x[:sum_win],lose:x[:sum_lose])
  end
  def self.refresh_all
   DB.transaction{
     self.all.each{|res|
       res.update_prizes
       res.update_winlose
     }
   }
  end
end

class ContestPromotionCache < Sequel::Model(:contest_promotion_caches)
  many_to_one :contest_user
  serialize_attributes Kagetra::serialize_enum([:a,:b,:c,:d,:e,:f,:g]), :class_rank
  serialize_attributes Kagetra::serialize_enum([:rank_up, :dash, :a_champ]), :promotion # 昇級, ダッシュ, A級優勝
  def validate
    super
    if promotion == :a_champ and a_champ_count.nil? then
      errors.add(:a_champ_count, 'cannot be empty if promotion == :a_champ')
    elsif promotion != :a_champ and not a_champ_count.nil? then
      errors.add(:a_champ_count, 'must be empty if promotion != :a_champ')
    end
  end
end


class ContestPrize < Sequel::Model(:contest_prizes)
  many_to_one :contest_class
  many_to_one :contest_user
  add_input_transformer_custom(:prize){|v| v && v.gsub("（","(").gsub("）",")").gsub(/\s+/,"")}
  serialize_attributes Kagetra::serialize_enum([:rank_up, :dash, :a_champ]), :promotion # 昇級, ダッシュ, A級優勝
  serialized_attr_accessor :promotion__rank_up, :promotion__a_champ

  def before_save
    self.contest_class_id = self.contest_user.contest_class_id
    if self.prize.to_s.empty?.! then
      self.prize = Kagetra::Utils.zenkaku_to_hankaku(self.prize.strip)
      if /\((.+)\)/ =~ self.prize then
        self.promotion = case $1
        when 'ダッシュ' then :dash
        when '昇級' then :rank_up
        end
      end
      if self.prize.start_with?("優勝") and self.contest_class.class_rank == :a then
        self.promotion = :a_champ
      end
      self.rank = Kagetra::Utils.rank_from_prize(self.prize)
    end
    super
  end
  def after_save
    super
    pt = (self.point || 0)
    pl = (self.point_local || 0)
    if pt > 0 or pl > 0 then
      self.contest_user.update(point:pt,point_local:pl)
    end
    self.contest_class.event.update_cache_prizes
    if [:rank_up,:a_champ].include?(self.promotion) then
      self.save_promotion_cache
    end
  end

  def after_destroy
    self.contest_user.update(point:0,point_local:0)
    self.contest_class.event.update_cache_prizes
    super
  end

  def save_promotion_cache
    event = self.contest_class.event
    user_name = self.contest_user.name
    contest_users = ContestUser.where(name:user_name)
    promotions = ContestPrize.where(contest_user_id:contest_users.map(&:id),promotion: ContestPrize.promotion__rank_up)
    prev_promotion = promotions.map{|x|x.contest_class.event}.select{|x|x.date < event.date}.sort_by(&:date).last
    query_base = Event.where(kind:Event.kind__contest,id:contest_users.map(&:event_id)).order(Sequel.asc(:date))
    if prev_promotion.nil?.! then
      query_base = query_base.where{ date > prev_promotion.date}
    end
    debut_date = query_base.first.date

    # 東京都大会のように非公認大会であっても昇級できる大会もあるのでその分を考慮
    contests = Event.where(id:contest_users.map(&:event_id),kind: Event.kind__contest,official:true,team_size:1).where{ (date >= debut_date) & (date < event.date) }.count + 1
    class_rank = self.contest_class.class_rank || Kagetra::Utils.class_from_name(self.contest_class.class_name)

    a_champ_count = if self.promotion == :a_champ then
      ContestPrize.where(contest_user_id:contest_users.map(&:id),promotion: ContestPrize.promotion__a_champ).map{|x|x.contest_class.event}.select{|x|x.date < event.date}.size + 1
    end

    data = {
      contest_user_id: self.contest_user_id,
      prize: self.prize.sub(/\(.*\)/,""),
      class_name: self.contest_class.class_name,
      user_name: user_name,
      event_id: event.id,
      event_name: event.name,
      event_date: event.date,
      contests: contests,
      debut_date: debut_date,
      promotion: self.promotion,
      class_rank: class_rank,
      a_champ_count: a_champ_count
    }
    ContestPromotionCache.update_or_create({contest_prize_id:self.id},data)
  end
end

class ContestGame < Sequel::Model(:contest_games)
  plugin :single_table_inheritance, :type, model_map:{'single'=>:ContestSingleGame, 'team'=>:ContestTeamGame}
  set_allowed_columns :type, :event_id, :contest_user_id, :result, :score_str, :score_int, :comment, :opponent_name, :opponent_belongs
  many_to_one :event
  many_to_one :contest_user
  add_input_transformer_custom(:opponent_name,:opponent_belongs){|v| v && v.gsub(/\s+/,"")}
  serialize_attributes Kagetra::serialize_enum([:now,:win,:lose,:default_win]), :result
  serialized_attr_accessor :result__lose,:result__win

  def before_save
    self.event = self.contest_user.event if self.event.nil?
    self.score_int = Kagetra::Utils.eval_score_char(self.score_str)
    super
  end

  # TODO: 複数の勝ち負けの一括更新に対応
  def after_save
    super
    u = self.contest_user
    updates = Hash[[:win,:lose].map{|sym|
      s = self.class.serialization_map[:result].call(sym)
      [sym,u.games_dataset.where(result:s).count]
    }]
    u.update(updates)
    u.event.update_cache_winlose
  end
end

class ContestSingleGame < ContestGame
  set_allowed_columns *(allowed_columns + [:contest_class_id,:round])
  many_to_one :contest_class
  def before_save
    self.contest_class_id = self.contest_user.contest_class_id
    super
  end
  def validate
    super
    validates_not_null :contest_class_id
    validates_not_null :round
  end
end

class ContestTeamGame < ContestGame
  set_allowed_columns *(allowed_columns + [:contest_team_opponent_id,:opponent_order])
  many_to_one :contest_team_opponent
  def validate
    super
    validates_not_null :contest_team_opponent_id
  end
end

# 誰がどのチームの何将か(団体戦)
class ContestTeamMember < Sequel::Model(:contest_team_members)
  many_to_one :contest_user
  many_to_one :contest_team
end

# どのチームがどの級に出場しているか(団体戦)
class ContestTeam < Sequel::Model(:contest_teams)
  serialize_attributes Kagetra::serialize_enum([:rank_up, :rank_down]), :promotion # 昇級, 陥落
  many_to_one :contest_class
  one_to_many :members, class:'ContestTeamMember'
  one_to_many :opponents, class:'ContestTeamOpponent'
  def before_save
    if self.prize.to_s.empty?.! then
      self.prize = Kagetra::Utils.zenkaku_to_hankaku(self.prize.strip)
      if /\((.+)\)/ =~ self.prize then
        self.promotion = case $1
        when '昇級' then :rank_up
        when '陥落' then :rank_down
        end
      end
      self.rank = Kagetra::Utils.rank_from_prize(self.prize)
    end
    super
  end
  def after_save
    super
    self.contest_class.event.update_cache_prizes
  end
end

class ContestTeamOpponent < Sequel::Model(:contest_team_opponents)
  many_to_one :contest_team
  serialize_attributes Kagetra::serialize_enum([:team, :single]), :kind
  one_to_many :games, class:'ContestTeamGame' # 試合結果(団体戦)
  def validate
    super
    if kind == :single and not name.nil? then
      errors.add(:name, 'must be empty if kind == :single')
    end
  end
end
