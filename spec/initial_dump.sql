-- MySQL dump 10.13  Distrib 5.5.40, for debian-linux-gnu (x86_64)
--
-- Host: localhost    Database: test2
-- ------------------------------------------------------
-- Server version	5.5.40-0ubuntu0.14.04.1

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `addr_books`
--

DROP TABLE IF EXISTS `addr_books`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `addr_books` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `user_id` int(11) NOT NULL,
  `album_item_id` int(11) DEFAULT NULL,
  `text` text COMMENT '暗号化+Base64されたテキスト，平文はJSON形式 {"項目1":"値1","項目2":"値2"}',
  PRIMARY KEY (`id`),
  UNIQUE KEY `user_id` (`user_id`),
  KEY `album_item_id` (`album_item_id`),
  KEY `addr_books_created_at_index` (`created_at`),
  KEY `addr_books_updated_at_index` (`updated_at`),
  CONSTRAINT `addr_books_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`),
  CONSTRAINT `addr_books_ibfk_2` FOREIGN KEY (`album_item_id`) REFERENCES `album_items` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='名簿';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `addr_books`
--

LOCK TABLES `addr_books` WRITE;
/*!40000 ALTER TABLE `addr_books` DISABLE KEYS */;
/*!40000 ALTER TABLE `addr_books` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `album_comment_logs`
--

DROP TABLE IF EXISTS `album_comment_logs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `album_comment_logs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `revision` int(11) NOT NULL,
  `patch` text NOT NULL COMMENT '差分情報',
  `user_id` int(11) DEFAULT NULL,
  `album_item_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `album_comment_logs_revision_album_item_id_index` (`revision`,`album_item_id`),
  KEY `user_id` (`user_id`),
  KEY `album_item_id` (`album_item_id`),
  KEY `album_comment_logs_created_at_index` (`created_at`),
  KEY `album_comment_logs_updated_at_index` (`updated_at`),
  CONSTRAINT `album_comment_logs_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `album_comment_logs_ibfk_2` FOREIGN KEY (`album_item_id`) REFERENCES `album_items` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='アルバムのコメントの変更履歴(created_atが編集日時)';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `album_comment_logs`
--

LOCK TABLES `album_comment_logs` WRITE;
/*!40000 ALTER TABLE `album_comment_logs` DISABLE KEYS */;
/*!40000 ALTER TABLE `album_comment_logs` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `album_group_events`
--

DROP TABLE IF EXISTS `album_group_events`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `album_group_events` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `album_group_id` int(11) NOT NULL,
  `event_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `album_group_id` (`album_group_id`),
  UNIQUE KEY `unique_album_group_events_album_group_id` (`album_group_id`),
  KEY `event_id` (`event_id`),
  KEY `album_group_events_created_at_index` (`created_at`),
  KEY `album_group_events_updated_at_index` (`updated_at`),
  CONSTRAINT `album_group_events_ibfk_1` FOREIGN KEY (`album_group_id`) REFERENCES `album_groups` (`id`) ON DELETE CASCADE,
  CONSTRAINT `album_group_events_ibfk_2` FOREIGN KEY (`event_id`) REFERENCES `events` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='大会結果とアルバムの関連付け';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `album_group_events`
--

LOCK TABLES `album_group_events` WRITE;
/*!40000 ALTER TABLE `album_group_events` DISABLE KEYS */;
/*!40000 ALTER TABLE `album_group_events` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `album_groups`
--

DROP TABLE IF EXISTS `album_groups`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `album_groups` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `name` varchar(72) DEFAULT NULL,
  `place` varchar(128) DEFAULT NULL,
  `comment` text,
  `start_at` date DEFAULT NULL COMMENT '開始日',
  `end_at` date DEFAULT NULL COMMENT '終了日',
  `dummy` tinyint(1) DEFAULT '0' COMMENT 'どのグループにも属していない写真のための擬似的なグループ',
  `year` int(11) DEFAULT NULL COMMENT '年ごとの集計のためにキャッシュする',
  `daily_choose_count` int(11) DEFAULT '0' COMMENT '含まれる写真のうち今日の一枚の対象になっている数',
  `has_comment_count` int(11) DEFAULT '0' COMMENT 'コメントの入っている写真の数',
  `has_tag_count` int(11) DEFAULT '0' COMMENT 'タグの入っている写真の数',
  `item_count` int(11) DEFAULT '0' COMMENT '含まれる写真数，毎回aggregateするのは遅いのでキャッッシュ',
  `owner_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `owner_id` (`owner_id`),
  KEY `album_groups_created_at_index` (`created_at`),
  KEY `album_groups_updated_at_index` (`updated_at`),
  KEY `album_groups_dummy_index` (`dummy`),
  KEY `album_groups_year_index` (`year`),
  CONSTRAINT `album_groups_ibfk_1` FOREIGN KEY (`owner_id`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='行事や大会単位でアルバムをまとめるためのもの';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `album_groups`
--

LOCK TABLES `album_groups` WRITE;
/*!40000 ALTER TABLE `album_groups` DISABLE KEYS */;
/*!40000 ALTER TABLE `album_groups` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `album_items`
--

DROP TABLE IF EXISTS `album_items`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `album_items` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `name` varchar(72) DEFAULT NULL,
  `place` varchar(128) DEFAULT NULL,
  `comment` text,
  `comment_revision` int(11) DEFAULT '0',
  `comment_updated_at` datetime DEFAULT NULL,
  `date` date DEFAULT NULL COMMENT '撮影日',
  `hourmin` varchar(50) DEFAULT NULL COMMENT '撮影時刻',
  `daily_choose` tinyint(1) DEFAULT '1' COMMENT '今日の一枚として選ばれるかどうか',
  `group_index` int(11) NOT NULL COMMENT 'グループの中での表示順',
  `rotate` int(11) DEFAULT '0' COMMENT '回転(右向き．0,90,180,270のどれか)',
  `orig_filename` varchar(128) DEFAULT NULL COMMENT 'アップロードされた元のファイル名',
  `tag_count` int(11) DEFAULT '0' COMMENT '写真にタグが何個付いているか',
  `tag_names` text COMMENT 'タグ名の入った配列をJSON化したもの',
  `owner_id` int(11) DEFAULT NULL,
  `group_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `owner_id` (`owner_id`),
  KEY `group_id` (`group_id`),
  KEY `album_items_created_at_index` (`created_at`),
  KEY `album_items_updated_at_index` (`updated_at`),
  KEY `album_items_comment_revision_index` (`comment_revision`),
  KEY `album_items_comment_updated_at_index` (`comment_updated_at`),
  CONSTRAINT `album_items_ibfk_1` FOREIGN KEY (`owner_id`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `album_items_ibfk_2` FOREIGN KEY (`group_id`) REFERENCES `album_groups` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='アルバムの各写真の情報';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `album_items`
--

LOCK TABLES `album_items` WRITE;
/*!40000 ALTER TABLE `album_items` DISABLE KEYS */;
/*!40000 ALTER TABLE `album_items` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `album_photos`
--

DROP TABLE IF EXISTS `album_photos`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `album_photos` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `path` varchar(255) NOT NULL,
  `width` int(11) NOT NULL,
  `height` int(11) NOT NULL,
  `format` varchar(50) DEFAULT NULL,
  `album_item_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `path` (`path`),
  UNIQUE KEY `album_item_id` (`album_item_id`),
  KEY `album_photos_created_at_index` (`created_at`),
  KEY `album_photos_updated_at_index` (`updated_at`),
  CONSTRAINT `album_photos_ibfk_1` FOREIGN KEY (`album_item_id`) REFERENCES `album_items` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `album_photos`
--

LOCK TABLES `album_photos` WRITE;
/*!40000 ALTER TABLE `album_photos` DISABLE KEYS */;
/*!40000 ALTER TABLE `album_photos` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `album_relations`
--

DROP TABLE IF EXISTS `album_relations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `album_relations` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `source_id` int(11) NOT NULL,
  `target_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_album_relations_u1` (`source_id`,`target_id`),
  KEY `target_id` (`target_id`),
  KEY `album_relations_created_at_index` (`created_at`),
  KEY `album_relations_updated_at_index` (`updated_at`),
  CONSTRAINT `album_relations_ibfk_1` FOREIGN KEY (`source_id`) REFERENCES `album_items` (`id`) ON DELETE CASCADE,
  CONSTRAINT `album_relations_ibfk_2` FOREIGN KEY (`target_id`) REFERENCES `album_items` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='アルバムの各写真同士の関連付け';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `album_relations`
--

LOCK TABLES `album_relations` WRITE;
/*!40000 ALTER TABLE `album_relations` DISABLE KEYS */;
/*!40000 ALTER TABLE `album_relations` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `album_tags`
--

DROP TABLE IF EXISTS `album_tags`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `album_tags` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `name` varchar(50) NOT NULL,
  `coord_x` int(11) DEFAULT NULL COMMENT 'X座標',
  `coord_y` int(11) DEFAULT NULL COMMENT 'Y座標',
  `radius` int(11) DEFAULT NULL COMMENT '円の半径',
  `album_item_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `album_item_id` (`album_item_id`),
  KEY `album_tags_created_at_index` (`created_at`),
  KEY `album_tags_updated_at_index` (`updated_at`),
  KEY `album_tags_name_index` (`name`),
  CONSTRAINT `album_tags_ibfk_1` FOREIGN KEY (`album_item_id`) REFERENCES `album_items` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='写真の特定の位置にタグ付けできる';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `album_tags`
--

LOCK TABLES `album_tags` WRITE;
/*!40000 ALTER TABLE `album_tags` DISABLE KEYS */;
/*!40000 ALTER TABLE `album_tags` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `album_thumbnails`
--

DROP TABLE IF EXISTS `album_thumbnails`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `album_thumbnails` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `path` varchar(255) NOT NULL,
  `width` int(11) NOT NULL,
  `height` int(11) NOT NULL,
  `format` varchar(50) DEFAULT NULL,
  `album_item_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `path` (`path`),
  UNIQUE KEY `album_item_id` (`album_item_id`),
  KEY `album_thumbnails_created_at_index` (`created_at`),
  KEY `album_thumbnails_updated_at_index` (`updated_at`),
  CONSTRAINT `album_thumbnails_ibfk_1` FOREIGN KEY (`album_item_id`) REFERENCES `album_items` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `album_thumbnails`
--

LOCK TABLES `album_thumbnails` WRITE;
/*!40000 ALTER TABLE `album_thumbnails` DISABLE KEYS */;
/*!40000 ALTER TABLE `album_thumbnails` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `bbs_items`
--

DROP TABLE IF EXISTS `bbs_items`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `bbs_items` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `remote_host` varchar(72) DEFAULT NULL,
  `remote_addr` varchar(48) DEFAULT NULL,
  `user_agent` varchar(255) DEFAULT NULL,
  `body` text NOT NULL COMMENT '内容',
  `user_name` varchar(24) NOT NULL COMMENT '書き込んだ人の名前',
  `real_name` varchar(24) DEFAULT NULL COMMENT '内部的な名前と書き込んだ名前が違う場合に使用',
  `thread_id` int(11) NOT NULL,
  `user_id` int(11) DEFAULT NULL,
  `is_first` tinyint(1) DEFAULT '0' COMMENT 'スレッドにおける最初の書き込み',
  PRIMARY KEY (`id`),
  KEY `thread_id` (`thread_id`),
  KEY `user_id` (`user_id`),
  KEY `bbs_items_created_at_index` (`created_at`),
  KEY `bbs_items_updated_at_index` (`updated_at`),
  KEY `bbs_items_is_first_index` (`is_first`),
  CONSTRAINT `bbs_items_ibfk_1` FOREIGN KEY (`thread_id`) REFERENCES `bbs_threads` (`id`) ON DELETE CASCADE,
  CONSTRAINT `bbs_items_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='掲示板の書き込み';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `bbs_items`
--

LOCK TABLES `bbs_items` WRITE;
/*!40000 ALTER TABLE `bbs_items` DISABLE KEYS */;
/*!40000 ALTER TABLE `bbs_items` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `bbs_threads`
--

DROP TABLE IF EXISTS `bbs_threads`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `bbs_threads` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `last_comment_date` datetime DEFAULT NULL COMMENT 'スレッドに最後に書き込んだ日時',
  `last_comment_user_id` int(11) DEFAULT NULL COMMENT 'スレッドに最後に書き込んだユーザ',
  `comment_count` int(11) DEFAULT '0' COMMENT 'コメント数(毎回aggregateするのは遅いのでキャッシュ)',
  `title` varchar(48) NOT NULL,
  `public` tinyint(1) DEFAULT '0' COMMENT '外部公開されているか',
  PRIMARY KEY (`id`),
  KEY `last_comment_user_id` (`last_comment_user_id`),
  KEY `bbs_threads_created_at_index` (`created_at`),
  KEY `bbs_threads_updated_at_index` (`updated_at`),
  KEY `bbs_threads_last_comment_date_index` (`last_comment_date`),
  CONSTRAINT `bbs_threads_ibfk_1` FOREIGN KEY (`last_comment_user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='掲示板のスレッド';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `bbs_threads`
--

LOCK TABLES `bbs_threads` WRITE;
/*!40000 ALTER TABLE `bbs_threads` DISABLE KEYS */;
/*!40000 ALTER TABLE `bbs_threads` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `contest_classes`
--

DROP TABLE IF EXISTS `contest_classes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `contest_classes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `class_name` varchar(16) NOT NULL COMMENT '級の名前',
  `class_rank` int(11) DEFAULT NULL COMMENT '級のランク（団体戦や非公認大会ならNULL，その他は1=>A級,2=>B級,3=>C級,4=>D級...）',
  `index` int(11) NOT NULL COMMENT '順番',
  `num_person` int(11) DEFAULT NULL COMMENT 'その級の他会の人も含む出場人数(個人戦のみ)',
  `round_name` text COMMENT '順位決定戦の名前(個人戦のみ)，{"4":"準決勝","5":"決勝"}のような形式',
  `event_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_contest_classes_u1` (`event_id`,`class_name`),
  KEY `contest_classes_created_at_index` (`created_at`),
  KEY `contest_classes_updated_at_index` (`updated_at`),
  CONSTRAINT `contest_classes_ibfk_1` FOREIGN KEY (`event_id`) REFERENCES `events` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='大会の各級の情報';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `contest_classes`
--

LOCK TABLES `contest_classes` WRITE;
/*!40000 ALTER TABLE `contest_classes` DISABLE KEYS */;
/*!40000 ALTER TABLE `contest_classes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `contest_games`
--

DROP TABLE IF EXISTS `contest_games`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `contest_games` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `type` varchar(8) NOT NULL COMMENT 'single:個人戦, team:団体戦',
  `event_id` int(11) NOT NULL,
  `contest_user_id` int(11) NOT NULL,
  `result` int(11) NOT NULL COMMENT '勝敗 => 1:対戦中,2:勝ち,3:負け,4:不戦勝',
  `score_str` varchar(8) DEFAULT NULL COMMENT '枚数(文字),''棄''とか''3+1''とかあるので文字列を用意しておく',
  `score_int` int(11) DEFAULT NULL COMMENT 'score_strをintとしてparseしたもの',
  `comment` text,
  `opponent_name` varchar(24) DEFAULT NULL COMMENT '対戦相手の名前',
  `opponent_belongs` varchar(36) DEFAULT NULL COMMENT '対戦相手の所属，基本的には個人戦のみ使用するが団体戦でも対戦相手の所属がバラバラな場合はここに書く',
  `contest_class_id` int(11) DEFAULT NULL COMMENT '個人戦用',
  `round` int(11) DEFAULT NULL COMMENT '個人戦用:回戦',
  `contest_team_opponent_id` int(11) DEFAULT NULL COMMENT '団体戦用',
  `opponent_order` int(11) DEFAULT NULL COMMENT '団体戦用:相手の将順',
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_contest_games_u1` (`contest_user_id`,`contest_class_id`,`round`),
  UNIQUE KEY `unique_contest_games_u2` (`event_id`,`contest_user_id`,`contest_class_id`,`round`),
  UNIQUE KEY `unique_contest_games_u3` (`event_id`,`contest_user_id`,`contest_team_opponent_id`),
  KEY `contest_class_id` (`contest_class_id`),
  KEY `contest_team_opponent_id` (`contest_team_opponent_id`),
  KEY `contest_games_created_at_index` (`created_at`),
  KEY `contest_games_updated_at_index` (`updated_at`),
  KEY `contest_games_score_int_index` (`score_int`),
  KEY `contest_games_opponent_name_index` (`opponent_name`),
  CONSTRAINT `contest_games_ibfk_1` FOREIGN KEY (`event_id`) REFERENCES `events` (`id`) ON DELETE CASCADE,
  CONSTRAINT `contest_games_ibfk_2` FOREIGN KEY (`contest_user_id`) REFERENCES `contest_users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `contest_games_ibfk_3` FOREIGN KEY (`contest_class_id`) REFERENCES `contest_classes` (`id`),
  CONSTRAINT `contest_games_ibfk_4` FOREIGN KEY (`contest_team_opponent_id`) REFERENCES `contest_team_opponents` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='大会の試合結果';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `contest_games`
--

LOCK TABLES `contest_games` WRITE;
/*!40000 ALTER TABLE `contest_games` DISABLE KEYS */;
/*!40000 ALTER TABLE `contest_games` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `contest_prizes`
--

DROP TABLE IF EXISTS `contest_prizes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `contest_prizes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `contest_class_id` int(11) NOT NULL,
  `contest_user_id` int(11) NOT NULL,
  `prize` varchar(32) NOT NULL COMMENT '実際の名前（優勝，全勝賞など）',
  `promotion` int(11) DEFAULT NULL COMMENT '1:昇級,2:ダッシュ,3:A級優勝',
  `point` int(11) DEFAULT '0' COMMENT 'A級のポイント',
  `point_local` int(11) DEFAULT '0' COMMENT '会内ポイント',
  `rank` int(11) DEFAULT NULL COMMENT '順位=>1:優勝,2:準優勝,3:三位,...',
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_contest_prizes_u1` (`contest_class_id`,`contest_user_id`),
  KEY `contest_user_id` (`contest_user_id`),
  KEY `contest_prizes_created_at_index` (`created_at`),
  KEY `contest_prizes_updated_at_index` (`updated_at`),
  CONSTRAINT `contest_prizes_ibfk_1` FOREIGN KEY (`contest_class_id`) REFERENCES `contest_classes` (`id`) ON DELETE CASCADE,
  CONSTRAINT `contest_prizes_ibfk_2` FOREIGN KEY (`contest_user_id`) REFERENCES `contest_users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `contest_prizes`
--

LOCK TABLES `contest_prizes` WRITE;
/*!40000 ALTER TABLE `contest_prizes` DISABLE KEYS */;
/*!40000 ALTER TABLE `contest_prizes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `contest_promotion_caches`
--

DROP TABLE IF EXISTS `contest_promotion_caches`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `contest_promotion_caches` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `prize` varchar(32) NOT NULL COMMENT 'contest_prizes.prizeのキャッシュ',
  `class_name` varchar(16) NOT NULL COMMENT 'contest_classes.class_nameのキャッシュ',
  `user_name` varchar(24) NOT NULL COMMENT 'contest_users.nameのキャッシュ',
  `event_date` date NOT NULL COMMENT 'events.dateのキャッシュ',
  `event_name` varchar(48) NOT NULL,
  `debut_date` date NOT NULL COMMENT '初出場大会もしくは前回昇級してから次の大会の日付',
  `contests` int(11) NOT NULL COMMENT '昇級した級の大会出場数',
  `promotion` int(11) NOT NULL COMMENT 'contest_prizes.promotionのキャッシュ',
  `class_rank` int(11) NOT NULL COMMENT 'contest_classes.class_rankのキャッシュ',
  `a_champ_count` int(11) DEFAULT NULL COMMENT '何回目のA級優勝か',
  `contest_prize_id` int(11) NOT NULL,
  `contest_user_id` int(11) NOT NULL,
  `event_id` int(11) NOT NULL COMMENT '昇級した大会',
  PRIMARY KEY (`id`),
  UNIQUE KEY `contest_prize_id` (`contest_prize_id`),
  UNIQUE KEY `contest_user_id` (`contest_user_id`),
  KEY `event_id` (`event_id`),
  KEY `contest_promotion_caches_created_at_index` (`created_at`),
  KEY `contest_promotion_caches_updated_at_index` (`updated_at`),
  CONSTRAINT `contest_promotion_caches_ibfk_1` FOREIGN KEY (`contest_prize_id`) REFERENCES `contest_prizes` (`id`) ON DELETE CASCADE,
  CONSTRAINT `contest_promotion_caches_ibfk_2` FOREIGN KEY (`contest_user_id`) REFERENCES `contest_users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `contest_promotion_caches_ibfk_3` FOREIGN KEY (`event_id`) REFERENCES `events` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='昇級ランキング用キャッシュ';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `contest_promotion_caches`
--

LOCK TABLES `contest_promotion_caches` WRITE;
/*!40000 ALTER TABLE `contest_promotion_caches` DISABLE KEYS */;
/*!40000 ALTER TABLE `contest_promotion_caches` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `contest_result_caches`
--

DROP TABLE IF EXISTS `contest_result_caches`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `contest_result_caches` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `event_id` int(11) NOT NULL,
  `win` int(11) DEFAULT '0' COMMENT '勝ち数の合計',
  `lose` int(11) DEFAULT '0' COMMENT '負け数の合計',
  `prizes` text COMMENT '入賞情報(JSON)',
  PRIMARY KEY (`id`),
  KEY `event_id` (`event_id`),
  KEY `contest_result_caches_created_at_index` (`created_at`),
  KEY `contest_result_caches_updated_at_index` (`updated_at`),
  CONSTRAINT `contest_result_caches_ibfk_1` FOREIGN KEY (`event_id`) REFERENCES `events` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='毎回aggregateするのは遅いのでキャッシュ';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `contest_result_caches`
--

LOCK TABLES `contest_result_caches` WRITE;
/*!40000 ALTER TABLE `contest_result_caches` DISABLE KEYS */;
/*!40000 ALTER TABLE `contest_result_caches` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `contest_team_members`
--

DROP TABLE IF EXISTS `contest_team_members`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `contest_team_members` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `contest_user_id` int(11) NOT NULL,
  `contest_team_id` int(11) NOT NULL,
  `order_num` int(11) NOT NULL COMMENT '将順',
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_contest_team_members_u1` (`contest_user_id`,`contest_team_id`),
  KEY `contest_team_id` (`contest_team_id`),
  KEY `contest_team_members_created_at_index` (`created_at`),
  KEY `contest_team_members_updated_at_index` (`updated_at`),
  CONSTRAINT `contest_team_members_ibfk_1` FOREIGN KEY (`contest_user_id`) REFERENCES `contest_users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `contest_team_members_ibfk_2` FOREIGN KEY (`contest_team_id`) REFERENCES `contest_teams` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='誰がどのチームの何将か(団体戦)';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `contest_team_members`
--

LOCK TABLES `contest_team_members` WRITE;
/*!40000 ALTER TABLE `contest_team_members` DISABLE KEYS */;
/*!40000 ALTER TABLE `contest_team_members` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `contest_team_opponents`
--

DROP TABLE IF EXISTS `contest_team_opponents`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `contest_team_opponents` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `contest_team_id` int(11) NOT NULL,
  `name` varchar(48) DEFAULT NULL COMMENT '対戦相手のチーム名',
  `round` int(11) NOT NULL COMMENT '回戦',
  `round_name` varchar(36) DEFAULT NULL COMMENT '決勝，順位決定戦など',
  `kind` int(11) NOT NULL COMMENT '1:団体戦,2:個人戦(大会形式は団体戦だけど相手の所属がバラバラ)',
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_contest_team_opponents_u1` (`contest_team_id`,`round`),
  KEY `contest_team_opponents_created_at_index` (`created_at`),
  KEY `contest_team_opponents_updated_at_index` (`updated_at`),
  CONSTRAINT `contest_team_opponents_ibfk_1` FOREIGN KEY (`contest_team_id`) REFERENCES `contest_teams` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='各チームが何回戦にどのチームと対戦したか';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `contest_team_opponents`
--

LOCK TABLES `contest_team_opponents` WRITE;
/*!40000 ALTER TABLE `contest_team_opponents` DISABLE KEYS */;
/*!40000 ALTER TABLE `contest_team_opponents` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `contest_teams`
--

DROP TABLE IF EXISTS `contest_teams`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `contest_teams` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `contest_class_id` int(11) NOT NULL,
  `name` varchar(48) NOT NULL COMMENT 'チーム名',
  `prize` varchar(24) DEFAULT NULL COMMENT 'チーム入賞',
  `rank` int(11) DEFAULT NULL COMMENT 'チーム入賞から推定した順位',
  `promotion` int(11) DEFAULT NULL COMMENT '1:昇級,2:陥落',
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_contest_teams_u1` (`contest_class_id`,`name`),
  KEY `contest_teams_created_at_index` (`created_at`),
  KEY `contest_teams_updated_at_index` (`updated_at`),
  CONSTRAINT `contest_teams_ibfk_1` FOREIGN KEY (`contest_class_id`) REFERENCES `contest_classes` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='どのチームがどの級に出場しているか(団体戦)';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `contest_teams`
--

LOCK TABLES `contest_teams` WRITE;
/*!40000 ALTER TABLE `contest_teams` DISABLE KEYS */;
/*!40000 ALTER TABLE `contest_teams` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `contest_users`
--

DROP TABLE IF EXISTS `contest_users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `contest_users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `name` varchar(24) NOT NULL COMMENT '後に改名する人や,usersに入ってない人のため',
  `user_id` int(11) DEFAULT NULL COMMENT 'usersテーブルから削除されたりした人のためにnullも許容',
  `event_id` int(11) NOT NULL,
  `contest_class_id` int(11) NOT NULL,
  `win` int(11) DEFAULT '0' COMMENT 'この大会の勝ち数(aggregateするのは遅いのでキャッシュ)',
  `lose` int(11) DEFAULT '0' COMMENT 'この大会の負け数(aggregateするのは遅いのでキャッシュ)',
  `point` int(11) DEFAULT '0' COMMENT 'A級のポイント(aggregateするのは遅いのでキャッシュ)',
  `point_local` int(11) DEFAULT '0' COMMENT '会内ポイント(aggregateするのは遅いのでキャッシュ)',
  `class_rank` int(11) DEFAULT NULL COMMENT 'contest_classesのclass_rankのキャッシュ',
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_contest_users_u1` (`user_id`,`event_id`),
  KEY `event_id` (`event_id`),
  KEY `contest_class_id` (`contest_class_id`),
  KEY `contest_users_created_at_index` (`created_at`),
  KEY `contest_users_updated_at_index` (`updated_at`),
  KEY `contest_users_name_index` (`name`),
  CONSTRAINT `contest_users_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `contest_users_ibfk_2` FOREIGN KEY (`event_id`) REFERENCES `events` (`id`) ON DELETE CASCADE,
  CONSTRAINT `contest_users_ibfk_3` FOREIGN KEY (`contest_class_id`) REFERENCES `contest_classes` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='大会出場者の情報';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `contest_users`
--

LOCK TABLES `contest_users` WRITE;
/*!40000 ALTER TABLE `contest_users` DISABLE KEYS */;
/*!40000 ALTER TABLE `contest_users` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `event_choices`
--

DROP TABLE IF EXISTS `event_choices`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `event_choices` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `name` varchar(24) NOT NULL,
  `positive` tinyint(1) NOT NULL COMMENT '「参加する」「はい」などの前向きな回答',
  `hide_result` tinyint(1) DEFAULT '0' COMMENT '回答した人の一覧を表示しない',
  `index` int(11) NOT NULL COMMENT '順序',
  `event_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `event_id` (`event_id`),
  KEY `event_choices_created_at_index` (`created_at`),
  KEY `event_choices_updated_at_index` (`updated_at`),
  CONSTRAINT `event_choices_ibfk_1` FOREIGN KEY (`event_id`) REFERENCES `events` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='大会/行事の選択肢';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `event_choices`
--

LOCK TABLES `event_choices` WRITE;
/*!40000 ALTER TABLE `event_choices` DISABLE KEYS */;
/*!40000 ALTER TABLE `event_choices` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `event_comments`
--

DROP TABLE IF EXISTS `event_comments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `event_comments` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `remote_host` varchar(72) DEFAULT NULL,
  `remote_addr` varchar(48) DEFAULT NULL,
  `user_agent` varchar(255) DEFAULT NULL,
  `body` text NOT NULL COMMENT '内容',
  `user_name` varchar(24) NOT NULL COMMENT '書き込んだ人の名前',
  `real_name` varchar(24) DEFAULT NULL COMMENT '内部的な名前と書き込んだ名前が違う場合に使用',
  `thread_id` int(11) NOT NULL,
  `user_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `thread_id` (`thread_id`),
  KEY `user_id` (`user_id`),
  KEY `event_comments_created_at_index` (`created_at`),
  KEY `event_comments_updated_at_index` (`updated_at`),
  CONSTRAINT `event_comments_ibfk_1` FOREIGN KEY (`thread_id`) REFERENCES `events` (`id`) ON DELETE CASCADE,
  CONSTRAINT `event_comments_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='大会/行事のコメント';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `event_comments`
--

LOCK TABLES `event_comments` WRITE;
/*!40000 ALTER TABLE `event_comments` DISABLE KEYS */;
/*!40000 ALTER TABLE `event_comments` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `event_groups`
--

DROP TABLE IF EXISTS `event_groups`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `event_groups` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `name` varchar(60) NOT NULL,
  `description` text,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`),
  KEY `event_groups_created_at_index` (`created_at`),
  KEY `event_groups_updated_at_index` (`updated_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='大会/行事のグループ';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `event_groups`
--

LOCK TABLES `event_groups` WRITE;
/*!40000 ALTER TABLE `event_groups` DISABLE KEYS */;
/*!40000 ALTER TABLE `event_groups` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `event_owners`
--

DROP TABLE IF EXISTS `event_owners`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `event_owners` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `user_id` int(11) NOT NULL,
  `event_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `event_owners_user_id_event_id_index` (`user_id`,`event_id`),
  KEY `event_id` (`event_id`),
  KEY `event_owners_created_at_index` (`created_at`),
  KEY `event_owners_updated_at_index` (`updated_at`),
  CONSTRAINT `event_owners_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `event_owners_ibfk_2` FOREIGN KEY (`event_id`) REFERENCES `events` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='大会行事を編集する権限のある人';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `event_owners`
--

LOCK TABLES `event_owners` WRITE;
/*!40000 ALTER TABLE `event_owners` DISABLE KEYS */;
/*!40000 ALTER TABLE `event_owners` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `event_user_choices`
--

DROP TABLE IF EXISTS `event_user_choices`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `event_user_choices` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `user_name` varchar(24) NOT NULL COMMENT '後で改名する人やUserにない人を登録できるように用意しておく',
  `cancel` tinyint(1) DEFAULT '0' COMMENT '登録取り消しフラグ',
  `attr_value_id` int(11) NOT NULL,
  `event_choice_id` int(11) NOT NULL,
  `user_id` int(11) DEFAULT NULL COMMENT 'usersにない人でも登録できるようにNULLを許可する',
  PRIMARY KEY (`id`),
  KEY `attr_value_id` (`attr_value_id`),
  KEY `event_choice_id` (`event_choice_id`),
  KEY `user_id` (`user_id`),
  KEY `event_user_choices_created_at_index` (`created_at`),
  KEY `event_user_choices_updated_at_index` (`updated_at`),
  CONSTRAINT `event_user_choices_ibfk_1` FOREIGN KEY (`attr_value_id`) REFERENCES `user_attribute_values` (`id`),
  CONSTRAINT `event_user_choices_ibfk_2` FOREIGN KEY (`event_choice_id`) REFERENCES `event_choices` (`id`) ON DELETE CASCADE,
  CONSTRAINT `event_user_choices_ibfk_3` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='どのユーザがどの選択肢を選んだか';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `event_user_choices`
--

LOCK TABLES `event_user_choices` WRITE;
/*!40000 ALTER TABLE `event_user_choices` DISABLE KEYS */;
/*!40000 ALTER TABLE `event_user_choices` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `events`
--

DROP TABLE IF EXISTS `events`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `events` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `last_comment_date` datetime DEFAULT NULL COMMENT 'スレッドに最後に書き込んだ日時',
  `last_comment_user_id` int(11) DEFAULT NULL COMMENT 'スレッドに最後に書き込んだユーザ',
  `comment_count` int(11) DEFAULT '0' COMMENT 'コメント数(毎回aggregateするのは遅いのでキャッシュ)',
  `name` varchar(48) NOT NULL COMMENT '名称',
  `formal_name` varchar(96) DEFAULT NULL COMMENT '正式名称',
  `official` tinyint(1) DEFAULT '1' COMMENT '公認大会かどうか',
  `kind` int(11) NOT NULL COMMENT '1:大会,2:コンパ/合宿/アフター,3:アンケート/購入',
  `team_size` int(11) DEFAULT '1' COMMENT '1:個人戦,3:三人団体戦,5:五人団体戦',
  `description` text COMMENT '備考',
  `deadline` date DEFAULT NULL COMMENT '締切日',
  `date` date DEFAULT NULL COMMENT '開催日時',
  `start_at` varchar(5) DEFAULT NULL COMMENT '開始時刻(HH:MM)',
  `end_at` varchar(5) DEFAULT NULL COMMENT '終了時刻(HH:MM)',
  `place` varchar(255) DEFAULT NULL COMMENT '場所',
  `done` tinyint(1) DEFAULT '0' COMMENT '終わった大会/行事',
  `public` tinyint(1) DEFAULT '1' COMMENT '公開されているか',
  `register_done` tinyint(1) DEFAULT '0' COMMENT '登録者確認済み(締切を過ぎてからN日経過のメッセージを表示しない)',
  `participant_count` int(11) DEFAULT '0' COMMENT '参加者数(毎回aggregateするのは遅いのでキャッシュ)',
  `contest_user_count` int(11) DEFAULT '0' COMMENT 'result_usersのcount(毎回aggregateするのは遅いのでキャッシュ)',
  `forbidden_attrs` text COMMENT '登録不可属性(user_attribute_values.idのリスト,json形式)',
  `hide_choice` tinyint(1) DEFAULT '0' COMMENT 'ユーザがどれを選択したかを管理者以外には分からなくする',
  `event_group_id` int(11) DEFAULT NULL,
  `aggregate_attr_id` int(11) NOT NULL COMMENT '集計属性',
  PRIMARY KEY (`id`),
  KEY `last_comment_user_id` (`last_comment_user_id`),
  KEY `event_group_id` (`event_group_id`),
  KEY `aggregate_attr_id` (`aggregate_attr_id`),
  KEY `events_created_at_index` (`created_at`),
  KEY `events_updated_at_index` (`updated_at`),
  KEY `events_last_comment_date_index` (`last_comment_date`),
  KEY `events_kind_index` (`kind`),
  KEY `events_date_index` (`date`),
  KEY `events_done_index` (`done`),
  KEY `events_public_index` (`public`),
  CONSTRAINT `events_ibfk_1` FOREIGN KEY (`last_comment_user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `events_ibfk_2` FOREIGN KEY (`event_group_id`) REFERENCES `event_groups` (`id`) ON DELETE SET NULL,
  CONSTRAINT `events_ibfk_3` FOREIGN KEY (`aggregate_attr_id`) REFERENCES `user_attribute_keys` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='大会/行事';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `events`
--

LOCK TABLES `events` WRITE;
/*!40000 ALTER TABLE `events` DISABLE KEYS */;
/*!40000 ALTER TABLE `events` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `my_confs`
--

DROP TABLE IF EXISTS `my_confs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `my_confs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `name` varchar(64) DEFAULT NULL,
  `value` text,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`),
  KEY `my_confs_created_at_index` (`created_at`),
  KEY `my_confs_updated_at_index` (`updated_at`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `my_confs`
--

LOCK TABLES `my_confs` WRITE;
/*!40000 ALTER TABLE `my_confs` DISABLE KEYS */;
INSERT INTO `my_confs` VALUES (1,'2014-11-22 11:14:44','2014-11-22 11:14:44','shared_password','{\"hash\":\"ogLsfG3KbZSBDd3S+uTBhO+UMnI3Hp16xc+KiSHiO0I=\",\"salt\":\"9M/hIYRb0TFUhzvO8ik2D7nGehhO5E78\"}'),(2,'2014-11-22 11:14:44','2014-11-22 11:14:44','addrbook_confirm_enc','{\"text\":\"U2FsdGVkX1/H59CmoUntEhTgn4ffyOwfIe4NMI9s1cuOavjz2gVBnczR0FpRNgzi\"}');
/*!40000 ALTER TABLE `my_confs` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `schedule_date_infos`
--

DROP TABLE IF EXISTS `schedule_date_infos`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `schedule_date_infos` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `date` date NOT NULL,
  `names` text,
  `holiday` tinyint(1) DEFAULT '0' COMMENT '休日かどうか',
  PRIMARY KEY (`id`),
  UNIQUE KEY `date` (`date`),
  KEY `schedule_date_infos_created_at_index` (`created_at`),
  KEY `schedule_date_infos_updated_at_index` (`updated_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='予定表の祝日の情報';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `schedule_date_infos`
--

LOCK TABLES `schedule_date_infos` WRITE;
/*!40000 ALTER TABLE `schedule_date_infos` DISABLE KEYS */;
/*!40000 ALTER TABLE `schedule_date_infos` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `schedule_items`
--

DROP TABLE IF EXISTS `schedule_items`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `schedule_items` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `date` date NOT NULL,
  `kind` int(11) NOT NULL DEFAULT '3' COMMENT '種類=>1:練習,2:コンパ,3:その他',
  `emphasis` int(11) NOT NULL DEFAULT '0' COMMENT '強調表示:下位bitからそれぞれname,start_at,end_at,place',
  `public` tinyint(1) DEFAULT '1' COMMENT '公開されているか',
  `name` varchar(48) NOT NULL,
  `start_at` varchar(5) DEFAULT NULL COMMENT '開始時刻(HH:MM)',
  `end_at` varchar(5) DEFAULT NULL COMMENT '終了時刻(HH:MM)',
  `place` varchar(48) DEFAULT NULL COMMENT '場所',
  `description` text,
  `owner_id` int(11) DEFAULT NULL COMMENT '所有者',
  PRIMARY KEY (`id`),
  KEY `owner_id` (`owner_id`),
  KEY `schedule_items_created_at_index` (`created_at`),
  KEY `schedule_items_updated_at_index` (`updated_at`),
  KEY `schedule_items_date_index` (`date`),
  CONSTRAINT `schedule_items_ibfk_1` FOREIGN KEY (`owner_id`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='予定表のアイテム';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `schedule_items`
--

LOCK TABLES `schedule_items` WRITE;
/*!40000 ALTER TABLE `schedule_items` DISABLE KEYS */;
/*!40000 ALTER TABLE `schedule_items` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `schema_info`
--

DROP TABLE IF EXISTS `schema_info`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `schema_info` (
  `version` int(11) NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `schema_info`
--

LOCK TABLES `schema_info` WRITE;
/*!40000 ALTER TABLE `schema_info` DISABLE KEYS */;
INSERT INTO `schema_info` VALUES (9);
/*!40000 ALTER TABLE `schema_info` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `user_attribute_keys`
--

DROP TABLE IF EXISTS `user_attribute_keys`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `user_attribute_keys` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `name` varchar(36) NOT NULL,
  `index` int(11) NOT NULL COMMENT '順序付け',
  PRIMARY KEY (`id`),
  KEY `user_attribute_keys_created_at_index` (`created_at`),
  KEY `user_attribute_keys_updated_at_index` (`updated_at`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8 COMMENT='ユーザ属性の名前(性別,級位など)';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `user_attribute_keys`
--

LOCK TABLES `user_attribute_keys` WRITE;
/*!40000 ALTER TABLE `user_attribute_keys` DISABLE KEYS */;
INSERT INTO `user_attribute_keys` VALUES (1,'2014-11-22 11:14:44','2014-11-22 11:14:44','全員',0),(2,'2014-11-22 11:14:44','2014-11-22 11:14:44','性',1),(3,'2014-11-22 11:14:44','2014-11-22 11:14:44','学年',2),(4,'2014-11-22 11:14:44','2014-11-22 11:14:44','級',3),(5,'2014-11-22 11:14:44','2014-11-22 11:14:44','段位',4),(6,'2014-11-22 11:14:44','2014-11-22 11:14:44','全日協',5);
/*!40000 ALTER TABLE `user_attribute_keys` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `user_attribute_values`
--

DROP TABLE IF EXISTS `user_attribute_values`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `user_attribute_values` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `attr_key_id` int(11) NOT NULL,
  `value` varchar(48) NOT NULL,
  `index` int(11) NOT NULL COMMENT '順序付け',
  `default` tinyint(1) DEFAULT '0' COMMENT '既定値かどうか',
  PRIMARY KEY (`id`),
  KEY `attr_key_id` (`attr_key_id`),
  KEY `user_attribute_values_created_at_index` (`created_at`),
  KEY `user_attribute_values_updated_at_index` (`updated_at`),
  CONSTRAINT `user_attribute_values_ibfk_1` FOREIGN KEY (`attr_key_id`) REFERENCES `user_attribute_keys` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=27 DEFAULT CHARSET=utf8 COMMENT='ユーザ属性の値(性別なら男または女,級位ならA級やB級など)';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `user_attribute_values`
--

LOCK TABLES `user_attribute_values` WRITE;
/*!40000 ALTER TABLE `user_attribute_values` DISABLE KEYS */;
INSERT INTO `user_attribute_values` VALUES (1,'2014-11-22 11:14:44','2014-11-22 11:14:44',1,'全員',0,1),(2,'2014-11-22 11:14:44','2014-11-22 11:14:44',2,'男',0,1),(3,'2014-11-22 11:14:44','2014-11-22 11:14:44',2,'女',1,0),(4,'2014-11-22 11:14:44','2014-11-22 11:14:44',3,'1年',0,1),(5,'2014-11-22 11:14:44','2014-11-22 11:14:44',3,'2年',1,0),(6,'2014-11-22 11:14:44','2014-11-22 11:14:44',3,'3年',2,0),(7,'2014-11-22 11:14:44','2014-11-22 11:14:44',3,'4年',3,0),(8,'2014-11-22 11:14:44','2014-11-22 11:14:44',3,'院生',4,0),(9,'2014-11-22 11:14:44','2014-11-22 11:14:44',3,'社会人',5,0),(10,'2014-11-22 11:14:44','2014-11-22 11:14:44',4,'A級',0,1),(11,'2014-11-22 11:14:44','2014-11-22 11:14:44',4,'B級',1,0),(12,'2014-11-22 11:14:44','2014-11-22 11:14:44',4,'C級',2,0),(13,'2014-11-22 11:14:44','2014-11-22 11:14:44',4,'D級',3,0),(14,'2014-11-22 11:14:44','2014-11-22 11:14:44',4,'E級',4,0),(15,'2014-11-22 11:14:44','2014-11-22 11:14:44',5,'0',0,1),(16,'2014-11-22 11:14:44','2014-11-22 11:14:44',5,'1',1,0),(17,'2014-11-22 11:14:44','2014-11-22 11:14:44',5,'2',2,0),(18,'2014-11-22 11:14:44','2014-11-22 11:14:44',5,'3',3,0),(19,'2014-11-22 11:14:44','2014-11-22 11:14:44',5,'4',4,0),(20,'2014-11-22 11:14:44','2014-11-22 11:14:44',5,'5',5,0),(21,'2014-11-22 11:14:44','2014-11-22 11:14:44',5,'6',6,0),(22,'2014-11-22 11:14:44','2014-11-22 11:14:44',5,'7',7,0),(23,'2014-11-22 11:14:44','2014-11-22 11:14:44',5,'8',8,0),(24,'2014-11-22 11:14:44','2014-11-22 11:14:44',5,'9',9,0),(25,'2014-11-22 11:14:44','2014-11-22 11:14:44',6,'○',0,1),(26,'2014-11-22 11:14:44','2014-11-22 11:14:44',6,'×',1,0);
/*!40000 ALTER TABLE `user_attribute_values` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `user_attributes`
--

DROP TABLE IF EXISTS `user_attributes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `user_attributes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `user_id` int(11) NOT NULL,
  `value_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`),
  KEY `value_id` (`value_id`),
  KEY `user_attributes_created_at_index` (`created_at`),
  KEY `user_attributes_updated_at_index` (`updated_at`),
  CONSTRAINT `user_attributes_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`),
  CONSTRAINT `user_attributes_ibfk_2` FOREIGN KEY (`value_id`) REFERENCES `user_attribute_values` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8 COMMENT='どのユーザがどの属性を持っているか';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `user_attributes`
--

LOCK TABLES `user_attributes` WRITE;
/*!40000 ALTER TABLE `user_attributes` DISABLE KEYS */;
INSERT INTO `user_attributes` VALUES (1,'2014-11-22 11:14:44','2014-11-22 11:14:44',1,1),(2,'2014-11-22 11:14:44','2014-11-22 11:14:44',1,2),(3,'2014-11-22 11:14:44','2014-11-22 11:14:44',1,4),(4,'2014-11-22 11:14:44','2014-11-22 11:14:44',1,10),(5,'2014-11-22 11:14:44','2014-11-22 11:14:44',1,15),(6,'2014-11-22 11:14:44','2014-11-22 11:14:44',1,25);
/*!40000 ALTER TABLE `user_attributes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `user_login_latests`
--

DROP TABLE IF EXISTS `user_login_latests`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `user_login_latests` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `remote_host` varchar(72) DEFAULT NULL,
  `remote_addr` varchar(48) DEFAULT NULL,
  `user_agent` varchar(255) DEFAULT NULL,
  `user_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`),
  KEY `user_login_latests_created_at_index` (`created_at`),
  KEY `user_login_latests_updated_at_index` (`updated_at`),
  CONSTRAINT `user_login_latests_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='最後のログイン(updated_atが実際のログインの日時)';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `user_login_latests`
--

LOCK TABLES `user_login_latests` WRITE;
/*!40000 ALTER TABLE `user_login_latests` DISABLE KEYS */;
/*!40000 ALTER TABLE `user_login_latests` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `user_login_logs`
--

DROP TABLE IF EXISTS `user_login_logs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `user_login_logs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `remote_host` varchar(72) DEFAULT NULL,
  `remote_addr` varchar(48) DEFAULT NULL,
  `user_agent` varchar(255) DEFAULT NULL,
  `user_id` int(11) NOT NULL,
  `counted` tinyint(1) DEFAULT '1' COMMENT 'ログイン数を増やしたかどうか',
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`),
  KEY `user_login_logs_created_at_index` (`created_at`),
  KEY `user_login_logs_updated_at_index` (`updated_at`),
  CONSTRAINT `user_login_logs_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='直近数日間のログイン履歴(created_atがログインの日時)';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `user_login_logs`
--

LOCK TABLES `user_login_logs` WRITE;
/*!40000 ALTER TABLE `user_login_logs` DISABLE KEYS */;
/*!40000 ALTER TABLE `user_login_logs` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `user_login_monthlies`
--

DROP TABLE IF EXISTS `user_login_monthlies`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `user_login_monthlies` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `user_id` int(11) NOT NULL,
  `year_month` varchar(8) NOT NULL,
  `count` int(11) DEFAULT '0',
  `rank` int(11) DEFAULT NULL COMMENT 'その月における順位',
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_user_login_monthlies_u1` (`user_id`,`year_month`),
  KEY `user_login_monthlies_created_at_index` (`created_at`),
  KEY `user_login_monthlies_updated_at_index` (`updated_at`),
  KEY `user_login_monthlies_year_month_index` (`year_month`),
  CONSTRAINT `user_login_monthlies_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='ユーザが月に何回ログインしたか';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `user_login_monthlies`
--

LOCK TABLES `user_login_monthlies` WRITE;
/*!40000 ALTER TABLE `user_login_monthlies` DISABLE KEYS */;
/*!40000 ALTER TABLE `user_login_monthlies` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `name` varchar(24) NOT NULL,
  `furigana` varchar(36) NOT NULL,
  `furigana_row` int(11) NOT NULL DEFAULT '-1' COMMENT '振り仮名の最初の一文字が五十音順のどの行か',
  `password_hash` varchar(44) NOT NULL,
  `password_salt` varchar(32) NOT NULL,
  `token` varchar(32) DEFAULT NULL COMMENT '認証用トークン',
  `token_expire` datetime DEFAULT NULL,
  `admin` tinyint(1) DEFAULT '0' COMMENT '管理者かどうか',
  `loginable` tinyint(1) DEFAULT '1' COMMENT 'ログインできるかどうか',
  `permission` int(11) DEFAULT '0' COMMENT '最下位ビットが1なら副管理者',
  `bbs_public_name` varchar(24) DEFAULT NULL COMMENT '掲示板の公開スレッドに書き込むときの名前',
  `show_new_from` datetime DEFAULT NULL COMMENT '掲示板やコメントなどの新着メッセージはこれ以降の日時のものを表示',
  PRIMARY KEY (`id`),
  KEY `users_created_at_index` (`created_at`),
  KEY `users_updated_at_index` (`updated_at`),
  KEY `users_furigana_row_index` (`furigana_row`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `users`
--

LOCK TABLES `users` WRITE;
/*!40000 ALTER TABLE `users` DISABLE KEYS */;
INSERT INTO `users` VALUES (1,'2014-11-22 11:14:44','2014-11-22 11:14:44','admin','admin',-1,'Ts0P6Y/q2m+tJ9XJjrOhrhiV/yPTxjMTNs0X09GD/J8=','+0uN+qjq6OQxXw07j8OzCELhCFWBDUJl',NULL,NULL,1,1,0,NULL,NULL);
/*!40000 ALTER TABLE `users` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `wiki_attached_files`
--

DROP TABLE IF EXISTS `wiki_attached_files`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `wiki_attached_files` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `path` varchar(255) DEFAULT NULL,
  `orig_name` varchar(128) DEFAULT NULL COMMENT '元のファイル名',
  `description` text,
  `size` int(11) NOT NULL,
  `owner_id` int(11) DEFAULT NULL,
  `wiki_item_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `owner_id` (`owner_id`),
  KEY `wiki_item_id` (`wiki_item_id`),
  KEY `wiki_attached_files_created_at_index` (`created_at`),
  KEY `wiki_attached_files_updated_at_index` (`updated_at`),
  CONSTRAINT `wiki_attached_files_ibfk_1` FOREIGN KEY (`owner_id`) REFERENCES `users` (`id`),
  CONSTRAINT `wiki_attached_files_ibfk_2` FOREIGN KEY (`wiki_item_id`) REFERENCES `wiki_items` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Wikiの添付ファイル';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `wiki_attached_files`
--

LOCK TABLES `wiki_attached_files` WRITE;
/*!40000 ALTER TABLE `wiki_attached_files` DISABLE KEYS */;
/*!40000 ALTER TABLE `wiki_attached_files` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `wiki_comments`
--

DROP TABLE IF EXISTS `wiki_comments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `wiki_comments` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `remote_host` varchar(72) DEFAULT NULL,
  `remote_addr` varchar(48) DEFAULT NULL,
  `user_agent` varchar(255) DEFAULT NULL,
  `body` text NOT NULL COMMENT '内容',
  `user_name` varchar(24) NOT NULL COMMENT '書き込んだ人の名前',
  `real_name` varchar(24) DEFAULT NULL COMMENT '内部的な名前と書き込んだ名前が違う場合に使用',
  `thread_id` int(11) NOT NULL,
  `user_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `thread_id` (`thread_id`),
  KEY `user_id` (`user_id`),
  KEY `wiki_comments_created_at_index` (`created_at`),
  KEY `wiki_comments_updated_at_index` (`updated_at`),
  CONSTRAINT `wiki_comments_ibfk_1` FOREIGN KEY (`thread_id`) REFERENCES `wiki_items` (`id`) ON DELETE CASCADE,
  CONSTRAINT `wiki_comments_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `wiki_comments`
--

LOCK TABLES `wiki_comments` WRITE;
/*!40000 ALTER TABLE `wiki_comments` DISABLE KEYS */;
/*!40000 ALTER TABLE `wiki_comments` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `wiki_item_logs`
--

DROP TABLE IF EXISTS `wiki_item_logs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `wiki_item_logs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `revision` int(11) NOT NULL,
  `patch` text NOT NULL COMMENT '差分情報',
  `user_id` int(11) DEFAULT NULL,
  `wiki_item_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `wiki_item_logs_revision_wiki_item_id_index` (`revision`,`wiki_item_id`),
  KEY `user_id` (`user_id`),
  KEY `wiki_item_id` (`wiki_item_id`),
  KEY `wiki_item_logs_created_at_index` (`created_at`),
  KEY `wiki_item_logs_updated_at_index` (`updated_at`),
  CONSTRAINT `wiki_item_logs_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `wiki_item_logs_ibfk_2` FOREIGN KEY (`wiki_item_id`) REFERENCES `wiki_items` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `wiki_item_logs`
--

LOCK TABLES `wiki_item_logs` WRITE;
/*!40000 ALTER TABLE `wiki_item_logs` DISABLE KEYS */;
/*!40000 ALTER TABLE `wiki_item_logs` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `wiki_items`
--

DROP TABLE IF EXISTS `wiki_items`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `wiki_items` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `last_comment_date` datetime DEFAULT NULL COMMENT 'スレッドに最後に書き込んだ日時',
  `last_comment_user_id` int(11) DEFAULT NULL COMMENT 'スレッドに最後に書き込んだユーザ',
  `comment_count` int(11) DEFAULT '0' COMMENT 'コメント数(毎回aggregateするのは遅いのでキャッシュ)',
  `title` varchar(72) NOT NULL,
  `public` tinyint(1) DEFAULT '0' COMMENT '外部公開されているか',
  `body` text NOT NULL,
  `revision` int(11) DEFAULT '0',
  `attached_count` int(11) DEFAULT '0' COMMENT '添付ファイルの数',
  `owner_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `title` (`title`),
  KEY `last_comment_user_id` (`last_comment_user_id`),
  KEY `owner_id` (`owner_id`),
  KEY `wiki_items_created_at_index` (`created_at`),
  KEY `wiki_items_updated_at_index` (`updated_at`),
  KEY `wiki_items_last_comment_date_index` (`last_comment_date`),
  CONSTRAINT `wiki_items_ibfk_1` FOREIGN KEY (`last_comment_user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `wiki_items_ibfk_2` FOREIGN KEY (`owner_id`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `wiki_items`
--

LOCK TABLES `wiki_items` WRITE;
/*!40000 ALTER TABLE `wiki_items` DISABLE KEYS */;
INSERT INTO `wiki_items` VALUES (1,'2014-11-22 11:14:45','2014-11-22 11:14:45',NULL,NULL,0,'Home',0,'This is home page of this wiki',1,0,1);
/*!40000 ALTER TABLE `wiki_items` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2014-11-22 11:15:08
