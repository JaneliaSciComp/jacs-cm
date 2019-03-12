-- MySQL dump 10.14  Distrib 5.5.44-MariaDB, for Linux (x86_64)
--
-- Host: prd-db    Database: flyportal
-- ------------------------------------------------------
-- Server version	5.6.24-enterprise-commercial-advanced-log

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
-- Temporary table structure for view `TAC_FOLDER_ID_LOAD_ID`
--

DROP TABLE IF EXISTS `TAC_FOLDER_ID_LOAD_ID`;
/*!50001 DROP VIEW IF EXISTS `TAC_FOLDER_ID_LOAD_ID`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
/*!50001 CREATE TABLE `TAC_FOLDER_ID_LOAD_ID` (
  `folder` tinyint NOT NULL,
  `folder_id` tinyint NOT NULL,
  `load_tile_id` tinyint NOT NULL
) ENGINE=MyISAM */;
SET character_set_client = @saved_cs_client;

--
-- Temporary table structure for view `TAC_FOLDER_ID_PATH`
--

DROP TABLE IF EXISTS `TAC_FOLDER_ID_PATH`;
/*!50001 DROP VIEW IF EXISTS `TAC_FOLDER_ID_PATH`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
/*!50001 CREATE TABLE `TAC_FOLDER_ID_PATH` (
  `folder_id` tinyint NOT NULL,
  `folder` tinyint NOT NULL
) ENGINE=MyISAM */;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `accession_ts_result`
--

DROP TABLE IF EXISTS `accession_ts_result`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `accession_ts_result` (
  `node_id` bigint(20) NOT NULL,
  `accession` varchar(255) NOT NULL,
  `docid` bigint(20) NOT NULL,
  `doctype` varchar(255) DEFAULT NULL,
  `docname` varchar(255) DEFAULT NULL,
  `headline` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`node_id`,`accession`,`docid`),
  KEY `FK49A8F8259881D82` (`node_id`),
  CONSTRAINT `FK49A8F8259881D82` FOREIGN KEY (`node_id`) REFERENCES `node` (`node_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `accounting`
--

DROP TABLE IF EXISTS `accounting`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `accounting` (
  `task_id` bigint(20) NOT NULL,
  `job_id` varchar(255) NOT NULL,
  `submit_time` datetime DEFAULT NULL,
  `start_time` datetime DEFAULT NULL,
  `end_time` datetime DEFAULT NULL,
  `wallclock` int(11) DEFAULT NULL,
  `user_time` int(11) DEFAULT NULL,
  `system_time` int(11) DEFAULT NULL,
  `cpu_time` int(11) DEFAULT NULL,
  `memory` float DEFAULT NULL,
  `vmemory` int(11) DEFAULT NULL,
  `maxvmem` int(11) DEFAULT NULL,
  `exit_status` smallint(6) DEFAULT NULL,
  `status` varchar(255) DEFAULT NULL,
  `queue` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`task_id`,`job_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `annotations`
--

DROP TABLE IF EXISTS `annotations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `annotations` (
  `id` bigint(20) NOT NULL,
  `namespace` varchar(255) DEFAULT NULL,
  `owner` varchar(255) NOT NULL,
  `term` varchar(255) NOT NULL,
  `COMMENT` varchar(2000) DEFAULT NULL,
  `conditional` tinytext,
  `value` varchar(400) DEFAULT NULL,
  `source` varchar(255) DEFAULT NULL,
  `createdDate` date DEFAULT NULL,
  `parentIdentifier` bigint(20) DEFAULT NULL,
  `deprecated` bit(1) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `ix1` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `assembly`
--

DROP TABLE IF EXISTS `assembly`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `assembly` (
  `assembly_id` bigint(20) NOT NULL,
  `assembly_acc` varchar(255) DEFAULT NULL,
  `description` varchar(255) DEFAULT NULL,
  `taxon_id` int(11) DEFAULT NULL,
  `sample_acc` varchar(255) DEFAULT NULL,
  `organism` varchar(255) DEFAULT NULL,
  `project` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`assembly_id`),
  UNIQUE KEY `assembly_acc` (`assembly_acc`),
  KEY `FKE9BE3DE6F841CE3D` (`sample_acc`),
  CONSTRAINT `FKE9BE3DE6F841CE3D` FOREIGN KEY (`sample_acc`) REFERENCES `bio_sample` (`sample_acc`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `assembly_library`
--

DROP TABLE IF EXISTS `assembly_library`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `assembly_library` (
  `assembly_id` bigint(20) NOT NULL,
  `library_id` bigint(20) NOT NULL,
  PRIMARY KEY (`assembly_id`,`library_id`),
  KEY `FK6624C3627F6AD893` (`library_id`),
  KEY `FK6624C3627FAE6265` (`assembly_id`),
  CONSTRAINT `FK6624C3627F6AD893` FOREIGN KEY (`library_id`) REFERENCES `library` (`library_id`),
  CONSTRAINT `FK6624C3627FAE6265` FOREIGN KEY (`assembly_id`) REFERENCES `assembly` (`assembly_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `author`
--

DROP TABLE IF EXISTS `author`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `author` (
  `name` varchar(255) NOT NULL,
  PRIMARY KEY (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `bio_material`
--

DROP TABLE IF EXISTS `bio_material`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `bio_material` (
  `material_id` bigint(20) NOT NULL,
  `project_symbol` varchar(255) NOT NULL,
  `material_acc` varchar(255) NOT NULL,
  `collection_site_id` bigint(20) DEFAULT NULL,
  `collection_host_id` bigint(20) DEFAULT NULL,
  `collection_start_time` datetime NOT NULL,
  `collection_stop_time` datetime NOT NULL,
  PRIMARY KEY (`material_id`),
  UNIQUE KEY `material_acc` (`material_acc`),
  KEY `FK6DF427EC261DC9E` (`collection_site_id`),
  KEY `FK6DF427E86AE34FE` (`collection_host_id`),
  CONSTRAINT `FK6DF427E86AE34FE` FOREIGN KEY (`collection_host_id`) REFERENCES `collection_host` (`host_id`),
  CONSTRAINT `FK6DF427EC261DC9E` FOREIGN KEY (`collection_site_id`) REFERENCES `collection_site` (`site_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `bio_material_sample`
--

DROP TABLE IF EXISTS `bio_material_sample`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `bio_material_sample` (
  `material_id` bigint(20) NOT NULL,
  `sample_id` bigint(20) NOT NULL,
  PRIMARY KEY (`material_id`,`sample_id`),
  KEY `FKE9DE068B320BB9A1` (`sample_id`),
  KEY `FKE9DE068B5C2345BB` (`material_id`),
  CONSTRAINT `FKE9DE068B320BB9A1` FOREIGN KEY (`sample_id`) REFERENCES `bio_sample` (`sample_id`),
  CONSTRAINT `FKE9DE068B5C2345BB` FOREIGN KEY (`material_id`) REFERENCES `bio_material` (`material_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `bio_sample`
--

DROP TABLE IF EXISTS `bio_sample`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `bio_sample` (
  `sample_id` bigint(20) NOT NULL,
  `sample_acc` varchar(255) NOT NULL,
  `sample_name` varchar(255) NOT NULL,
  `filter_min` double NOT NULL,
  `filter_max` double NOT NULL,
  `intellectual_property_notice` varchar(255) DEFAULT NULL,
  `sample_title` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`sample_id`),
  UNIQUE KEY `sample_acc` (`sample_acc`),
  UNIQUE KEY `sample_name` (`sample_name`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `bio_sample_comment`
--

DROP TABLE IF EXISTS `bio_sample_comment`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `bio_sample_comment` (
  `sample_id` bigint(20) NOT NULL,
  `comment_text` varchar(255) DEFAULT NULL,
  `comment_no` int(11) NOT NULL,
  PRIMARY KEY (`sample_id`,`comment_no`),
  KEY `bio_sample_comment_fk_sample` (`sample_id`),
  CONSTRAINT `bio_sample_comment_fk_sample` FOREIGN KEY (`sample_id`) REFERENCES `bio_sample` (`sample_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `bio_sequence`
--

DROP TABLE IF EXISTS `bio_sequence`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `bio_sequence` (
  `sequence_id` bigint(20) NOT NULL,
  `sequence_type_code` int(11) NOT NULL,
  `sequence` text NOT NULL,
  `source_id` int(11) NOT NULL,
  PRIMARY KEY (`sequence_id`),
  KEY `FK457C55188FE1C85A` (`sequence_type_code`),
  CONSTRAINT `FK457C55188FE1C85A` FOREIGN KEY (`sequence_type_code`) REFERENCES `sequence_type` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `blast_hit`
--

DROP TABLE IF EXISTS `blast_hit`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `blast_hit` (
  `blast_hit_id` bigint(20) NOT NULL,
  `subject_acc` varchar(255) DEFAULT NULL,
  `subject_begin` int(11) NOT NULL,
  `subject_end` int(11) NOT NULL,
  `subject_orientation` int(11) NOT NULL,
  `query_acc` varchar(255) DEFAULT NULL,
  `query_node_id` bigint(20) DEFAULT NULL,
  `query_begin` int(11) NOT NULL,
  `query_end` int(11) NOT NULL,
  `query_orientation` int(11) NOT NULL,
  `result_node_id` bigint(20) DEFAULT NULL,
  `result_rank` int(11) DEFAULT NULL,
  `program_used` varchar(255) NOT NULL,
  `blast_version` varchar(255) DEFAULT NULL,
  `bit_score` float DEFAULT NULL,
  `hsp_score` float DEFAULT NULL,
  `expect_score` double DEFAULT NULL,
  `comment` varchar(255) DEFAULT NULL,
  `length_alignment` int(11) DEFAULT NULL,
  `entropy` float DEFAULT NULL,
  `number_identical` int(11) DEFAULT NULL,
  `number_similar` int(11) DEFAULT NULL,
  `subject_length` int(11) DEFAULT NULL,
  `subject_gaps` int(11) DEFAULT NULL,
  `subject_gap_runs` int(11) DEFAULT NULL,
  `subject_stops` int(11) DEFAULT NULL,
  `subject_number_unalignable` int(11) DEFAULT NULL,
  `subject_frame` int(11) DEFAULT NULL,
  `query_length` int(11) DEFAULT NULL,
  `query_gaps` int(11) DEFAULT NULL,
  `query_gap_runs` int(11) DEFAULT NULL,
  `query_stops` int(11) DEFAULT NULL,
  `query_number_unalignable` int(11) DEFAULT NULL,
  `query_frame` int(11) DEFAULT NULL,
  `subject_align_string` varchar(4000) DEFAULT NULL,
  `midline_align_string` varchar(4000) DEFAULT NULL,
  `query_align_string` varchar(4000) DEFAULT NULL,
  PRIMARY KEY (`blast_hit_id`),
  KEY `FK6B3A98CC6CFFB02F` (`result_node_id`),
  KEY `FK6B3A98CC53DE1F60` (`result_node_id`),
  CONSTRAINT `FK6B3A98CC53DE1F60` FOREIGN KEY (`result_node_id`) REFERENCES `node` (`node_id`),
  CONSTRAINT `FK6B3A98CC6CFFB02F` FOREIGN KEY (`result_node_id`) REFERENCES `node` (`node_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `blast_result_node_defline_map`
--

DROP TABLE IF EXISTS `blast_result_node_defline_map`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `blast_result_node_defline_map` (
  `node_id` bigint(20) NOT NULL,
  `defline` varchar(255) DEFAULT NULL,
  `accession` varchar(255) NOT NULL DEFAULT '',
  PRIMARY KEY (`node_id`,`accession`),
  KEY `FKBDA1997472A9AE51` (`node_id`),
  CONSTRAINT `FKBDA1997472A9AE51` FOREIGN KEY (`node_id`) REFERENCES `node` (`node_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `blastdataset_node_members`
--

DROP TABLE IF EXISTS `blastdataset_node_members`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `blastdataset_node_members` (
  `dataset_node_id` bigint(20) NOT NULL,
  `blastdb_filenode_id` bigint(20) NOT NULL,
  PRIMARY KEY (`dataset_node_id`,`blastdb_filenode_id`),
  KEY `FK68149A3BA514BF71` (`dataset_node_id`),
  KEY `FK68149A3BE7F3E806` (`blastdb_filenode_id`),
  CONSTRAINT `FK68149A3BA514BF71` FOREIGN KEY (`dataset_node_id`) REFERENCES `node` (`node_id`),
  CONSTRAINT `FK68149A3BE7F3E806` FOREIGN KEY (`blastdb_filenode_id`) REFERENCES `node` (`node_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `collection_host`
--

DROP TABLE IF EXISTS `collection_host`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `collection_host` (
  `host_id` bigint(20) NOT NULL,
  `organism` varchar(255) NOT NULL,
  `taxon_id` int(11) DEFAULT NULL,
  `host_details` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`host_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `collection_site`
--

DROP TABLE IF EXISTS `collection_site`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `collection_site` (
  `site_id` bigint(20) NOT NULL,
  `site_type_code` int(11) NOT NULL,
  `region` varchar(255) NOT NULL,
  `location` varchar(255) DEFAULT NULL,
  `COMMENT` varchar(255) DEFAULT NULL,
  `site_description` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`site_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `data_file`
--

DROP TABLE IF EXISTS `data_file`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `data_file` (
  `oid` bigint(20) NOT NULL,
  `path` varchar(255) DEFAULT NULL,
  `info_location` varchar(255) DEFAULT NULL,
  `description` text,
  `size` bigint(20) DEFAULT NULL,
  `multifile_archive` bit(1) DEFAULT NULL,
  PRIMARY KEY (`oid`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `data_file_sample_link`
--

DROP TABLE IF EXISTS `data_file_sample_link`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `data_file_sample_link` (
  `data_file_id` bigint(20) NOT NULL,
  `sample_id` bigint(20) NOT NULL,
  PRIMARY KEY (`data_file_id`,`sample_id`),
  KEY `FK4E016321320BB9A1` (`sample_id`),
  KEY `FK4E0163219DDED49D` (`data_file_id`),
  CONSTRAINT `FK4E016321320BB9A1` FOREIGN KEY (`sample_id`) REFERENCES `bio_sample` (`sample_id`),
  CONSTRAINT `FK4E0163219DDED49D` FOREIGN KEY (`data_file_id`) REFERENCES `data_file` (`oid`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `data_source`
--

DROP TABLE IF EXISTS `data_source`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `data_source` (
  `source_id` bigint(20) NOT NULL,
  `source_name` varchar(255) NOT NULL,
  `data_version` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`source_id`),
  UNIQUE KEY `source_name` (`source_name`),
  KEY `data_source_key_source_name` (`source_name`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `dispatcher_job`
--

DROP TABLE IF EXISTS `dispatcher_job`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `dispatcher_job` (
  `dispatch_id` bigint(20) NOT NULL,
  `process_defn_name` varchar(255) NOT NULL,
  `dispatch_status` varchar(20) NOT NULL,
  `dispatched_task_id` bigint(20) NOT NULL,
  `dispatched_task_owner` varchar(255) NOT NULL,
  `dispatch_host` varchar(255) DEFAULT NULL,
  `creation_date` datetime NOT NULL,
  `dispatched_date` datetime DEFAULT NULL,
  `retries` int(11) DEFAULT NULL,
  PRIMARY KEY (`dispatch_id`),
  UNIQUE KEY `dispatcher_job_archive_task_uk_ind` (`dispatched_task_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `dispatcher_job_archive`
--

DROP TABLE IF EXISTS `dispatcher_job_archive`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `dispatcher_job_archive` (
  `dispatch_id` bigint(20) NOT NULL,
  `process_defn_name` varchar(255) NOT NULL,
  `dispatch_status` varchar(20) NOT NULL,
  `dispatched_task_id` bigint(20) NOT NULL,
  `dispatched_task_owner` varchar(255) NOT NULL,
  `dispatch_host` varchar(255) DEFAULT NULL,
  `creation_date` datetime NOT NULL,
  `dispatched_date` datetime DEFAULT NULL,
  `retries` int(11) DEFAULT NULL,
  UNIQUE KEY `dispatcher_job_archive_task_uk_ind` (`dispatched_task_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `entity`
--

DROP TABLE IF EXISTS `entity`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `entity` (
  `id` bigint(20) NOT NULL,
  `entity_type` varchar(64) NOT NULL,
  `creation_date` datetime DEFAULT NULL,
  `updated_date` datetime DEFAULT NULL,
  `name` varchar(4000) DEFAULT NULL,
  `owner_key` varchar(64) NOT NULL,
  `num_children` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `fk_owner_key6` (`owner_key`),
  KEY `fk_entity_type6` (`entity_type`),
  KEY `idx_num_children6` (`num_children`),
  KEY `entity_ind6` (`name`(767)),
  CONSTRAINT `fk_entity_type6` FOREIGN KEY (`entity_type`) REFERENCES `entityType` (`name`),
  CONSTRAINT `fk_subject_key6` FOREIGN KEY (`owner_key`) REFERENCES `subject` (`subject_key`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `entityAttribute`
--

DROP TABLE IF EXISTS `entityAttribute`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `entityAttribute` (
  `id` bigint(20) NOT NULL,
  `name` varchar(60) NOT NULL,
  `possibleValues` varchar(4000) DEFAULT NULL,
  `style` varchar(60) DEFAULT NULL,
  `description` text,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name_constraint` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `entityData`
--

DROP TABLE IF EXISTS `entityData`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `entityData` (
  `id` bigint(20) NOT NULL,
  `parent_entity_id` bigint(20) DEFAULT NULL,
  `entity_att` varchar(64) NOT NULL,
  `value` longtext,
  `creation_date` datetime DEFAULT NULL,
  `updated_date` datetime DEFAULT NULL,
  `orderIndex` int(11) DEFAULT NULL,
  `child_entity_id` bigint(20) DEFAULT NULL,
  `owner_key` varchar(64) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_owner_key7` (`owner_key`),
  KEY `fk_att7` (`entity_att`),
  KEY `fk_ed_child_id7` (`child_entity_id`),
  KEY `fk_ed_parent_id7` (`parent_entity_id`),
  KEY `value_prefix7` (`value`(512)),
  CONSTRAINT `fk_att7` FOREIGN KEY (`entity_att`) REFERENCES `entityAttribute` (`name`),
  CONSTRAINT `fk_ed_child_id7` FOREIGN KEY (`child_entity_id`) REFERENCES `entity` (`id`),
  CONSTRAINT `fk_ed_parent_id7` FOREIGN KEY (`parent_entity_id`) REFERENCES `entity` (`id`),
  CONSTRAINT `fk_subject_key7` FOREIGN KEY (`owner_key`) REFERENCES `subject` (`subject_key`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8 */ ;
/*!50003 SET character_set_results = utf8 */ ;
/*!50003 SET collation_connection  = utf8_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`%`*/ /*!50003 TRIGGER scality_object_tracker AFTER INSERT ON entityData
FOR EACH ROW
BEGIN
     IF NEW.entity_att='Scality BPID' THEN
         INSERT INTO scality_objects values (NEW.id, NEW.parent_entity_id, NEW.value, NEW.creation_date, NEW.owner_key);
     END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `entityStatus`
--

DROP TABLE IF EXISTS `entityStatus`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `entityStatus` (
  `id` bigint(20) NOT NULL,
  `name` varchar(60) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name_constraint` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `entityType`
--

DROP TABLE IF EXISTS `entityType`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `entityType` (
  `id` bigint(20) NOT NULL,
  `sequence` decimal(10,0) DEFAULT NULL,
  `name` varchar(60) DEFAULT NULL,
  `style` varchar(60) DEFAULT NULL,
  `description` text,
  `iconurl` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name_constraint` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `entityTypeAttribute`
--

DROP TABLE IF EXISTS `entityTypeAttribute`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `entityTypeAttribute` (
  `entity_type_id` bigint(20) NOT NULL,
  `entity_att_id` bigint(20) NOT NULL,
  PRIMARY KEY (`entity_type_id`,`entity_att_id`),
  KEY `fk_entity_type_id` (`entity_type_id`),
  KEY `fk_entity_att_id` (`entity_att_id`),
  CONSTRAINT `fk_entity_att_id` FOREIGN KEY (`entity_att_id`) REFERENCES `entityAttribute` (`id`),
  CONSTRAINT `fk_entity_type_id` FOREIGN KEY (`entity_type_id`) REFERENCES `entityType` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `entity_actor_permission`
--

DROP TABLE IF EXISTS `entity_actor_permission`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `entity_actor_permission` (
  `id` bigint(20) NOT NULL,
  `entity_id` bigint(20) NOT NULL,
  `subject_key` varchar(64) DEFAULT NULL,
  `permissions` varchar(8) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `fk_subject_entity` (`subject_key`,`entity_id`),
  KEY `fk_entity_id9` (`entity_id`),
  KEY `idx_subject_key9` (`subject_key`),
  CONSTRAINT `fk_entity_id9` FOREIGN KEY (`entity_id`) REFERENCES `entity` (`id`),
  CONSTRAINT `fk_subject_key9` FOREIGN KEY (`subject_key`) REFERENCES `subject` (`subject_key`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `entity_type`
--

DROP TABLE IF EXISTS `entity_type`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `entity_type` (
  `code` int(11) NOT NULL,
  `name` varchar(255) NOT NULL,
  `abbrev` varchar(255) NOT NULL,
  `description` varchar(255) DEFAULT NULL,
  `sequence_type` int(11) NOT NULL,
  PRIMARY KEY (`code`),
  UNIQUE KEY `name` (`name`),
  UNIQUE KEY `abbrev` (`abbrev`),
  KEY `FK4C655A168ACB887E` (`sequence_type`),
  CONSTRAINT `FK4C655A168ACB887E` FOREIGN KEY (`sequence_type`) REFERENCES `sequence_type` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `geo_path_point`
--

DROP TABLE IF EXISTS `geo_path_point`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `geo_path_point` (
  `path_id` bigint(20) NOT NULL,
  `point_id` bigint(20) NOT NULL,
  `path_order` int(11) NOT NULL,
  PRIMARY KEY (`path_id`,`path_order`),
  KEY `FKD6ED66A463C79B44` (`path_id`),
  KEY `FKD6ED66A4E761E550` (`point_id`),
  CONSTRAINT `FKD6ED66A463C79B44` FOREIGN KEY (`path_id`) REFERENCES `collection_site` (`site_id`),
  CONSTRAINT `FKD6ED66A4E761E550` FOREIGN KEY (`point_id`) REFERENCES `collection_site` (`site_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `geo_point`
--

DROP TABLE IF EXISTS `geo_point`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `geo_point` (
  `location_id` bigint(20) NOT NULL,
  `country` varchar(255) NOT NULL,
  `longitude` varchar(255) NOT NULL,
  `latitude` varchar(255) NOT NULL,
  `altitude` varchar(255) DEFAULT NULL,
  `depth` varchar(255) NOT NULL,
  PRIMARY KEY (`location_id`),
  KEY `FK3BADC722EC852D0B` (`location_id`),
  CONSTRAINT `FK3BADC722EC852D0B` FOREIGN KEY (`location_id`) REFERENCES `collection_site` (`site_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `hierarchy_node`
--

DROP TABLE IF EXISTS `hierarchy_node`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `hierarchy_node` (
  `oid` bigint(20) NOT NULL,
  `name` varchar(255) DEFAULT NULL,
  `description` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`oid`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `hierarchy_node_data_file_link`
--

DROP TABLE IF EXISTS `hierarchy_node_data_file_link`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `hierarchy_node_data_file_link` (
  `hierarchy_node_id` bigint(20) NOT NULL,
  `data_file_id` bigint(20) NOT NULL,
  `position` int(11) NOT NULL,
  PRIMARY KEY (`hierarchy_node_id`,`position`),
  KEY `FKDBD10D5BC973E5D7` (`hierarchy_node_id`),
  KEY `FKDBD10D5B9DDED49D` (`data_file_id`),
  CONSTRAINT `FKDBD10D5B9DDED49D` FOREIGN KEY (`data_file_id`) REFERENCES `data_file` (`oid`),
  CONSTRAINT `FKDBD10D5BC973E5D7` FOREIGN KEY (`hierarchy_node_id`) REFERENCES `hierarchy_node` (`oid`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `hierarchy_node_to_children_link`
--

DROP TABLE IF EXISTS `hierarchy_node_to_children_link`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `hierarchy_node_to_children_link` (
  `parent_id` bigint(20) NOT NULL,
  `child_id` bigint(20) NOT NULL,
  `position` int(11) NOT NULL,
  PRIMARY KEY (`parent_id`,`position`),
  KEY `FK4A0BA5891C3ADC87` (`child_id`),
  KEY `FK4A0BA58934B77639` (`parent_id`),
  CONSTRAINT `FK4A0BA5891C3ADC87` FOREIGN KEY (`child_id`) REFERENCES `hierarchy_node` (`oid`),
  CONSTRAINT `FK4A0BA58934B77639` FOREIGN KEY (`parent_id`) REFERENCES `hierarchy_node` (`oid`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `library`
--

DROP TABLE IF EXISTS `library`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `library` (
  `library_id` bigint(20) NOT NULL,
  `library_acc` varchar(255) DEFAULT NULL,
  `max_insert_size` int(11) DEFAULT NULL,
  `min_insert_size` int(11) DEFAULT NULL,
  `number_of_reads` int(11) NOT NULL,
  `sequencing_technology` varchar(255) DEFAULT NULL,
  `sample_acc` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`library_id`),
  UNIQUE KEY `library_acc` (`library_acc`),
  KEY `FK9E824BBF841CE3D` (`sample_acc`),
  CONSTRAINT `FK9E824BBF841CE3D` FOREIGN KEY (`sample_acc`) REFERENCES `bio_sample` (`sample_acc`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `march04_entity`
--

DROP TABLE IF EXISTS `march04_entity`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `march04_entity` (
  `id` bigint(20) NOT NULL,
  `entity_type` varchar(64) NOT NULL,
  `creation_date` datetime DEFAULT NULL,
  `updated_date` datetime DEFAULT NULL,
  `name` varchar(4000) DEFAULT NULL,
  `owner_key` varchar(64) NOT NULL,
  `num_children` int(11) NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `march04_entity_actor_permission`
--

DROP TABLE IF EXISTS `march04_entity_actor_permission`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `march04_entity_actor_permission` (
  `id` bigint(20) NOT NULL,
  `entity_id` bigint(20) NOT NULL,
  `subject_key` varchar(64) DEFAULT NULL,
  `permissions` varchar(8) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `march04_entity_data`
--

DROP TABLE IF EXISTS `march04_entity_data`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `march04_entity_data` (
  `id` bigint(20) NOT NULL,
  `parent_entity_id` bigint(20) DEFAULT NULL,
  `entity_att` varchar(64) NOT NULL,
  `value` longtext,
  `creation_date` datetime DEFAULT NULL,
  `updated_date` datetime DEFAULT NULL,
  `orderIndex` int(11) DEFAULT NULL,
  `child_entity_id` bigint(20) DEFAULT NULL,
  `owner_key` varchar(64) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ml_entityData_2225354542281654588`
--

DROP TABLE IF EXISTS `ml_entityData_2225354542281654588`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ml_entityData_2225354542281654588` (
  `id` bigint(20) NOT NULL,
  `parent_entity_id` bigint(20) DEFAULT NULL,
  `entity_att` varchar(64) NOT NULL,
  `value` longtext,
  `creation_date` datetime DEFAULT NULL,
  `updated_date` datetime DEFAULT NULL,
  `orderIndex` int(11) DEFAULT NULL,
  `child_entity_id` bigint(20) DEFAULT NULL,
  `owner_key` varchar(64) NOT NULL,
  UNIQUE KEY `ml_entityData_uk` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ml_entityData_prod_2225354542281654588`
--

DROP TABLE IF EXISTS `ml_entityData_prod_2225354542281654588`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ml_entityData_prod_2225354542281654588` (
  `id` bigint(20) NOT NULL,
  `parent_entity_id` bigint(20) DEFAULT NULL,
  `entity_att` varchar(64) NOT NULL,
  `value` longtext,
  `creation_date` datetime DEFAULT NULL,
  `updated_date` datetime DEFAULT NULL,
  `orderIndex` int(11) DEFAULT NULL,
  `child_entity_id` bigint(20) DEFAULT NULL,
  `owner_key` varchar(64) NOT NULL,
  UNIQUE KEY `ml_entityData_uk` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ml_entity_2225354542281654588`
--

DROP TABLE IF EXISTS `ml_entity_2225354542281654588`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ml_entity_2225354542281654588` (
  `id` bigint(20) NOT NULL,
  `entity_type` varchar(64) NOT NULL,
  `creation_date` datetime DEFAULT NULL,
  `updated_date` datetime DEFAULT NULL,
  `name` varchar(4000) DEFAULT NULL,
  `owner_key` varchar(64) NOT NULL,
  `num_children` int(11) NOT NULL DEFAULT '0',
  UNIQUE KEY `ml_entity_uk` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ml_entity_prod_2225354542281654588`
--

DROP TABLE IF EXISTS `ml_entity_prod_2225354542281654588`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ml_entity_prod_2225354542281654588` (
  `id` bigint(20) NOT NULL,
  `entity_type` varchar(64) NOT NULL,
  `creation_date` datetime DEFAULT NULL,
  `updated_date` datetime DEFAULT NULL,
  `name` varchar(4000) DEFAULT NULL,
  `owner_key` varchar(64) NOT NULL,
  `num_children` int(11) NOT NULL DEFAULT '0',
  UNIQUE KEY `ml_entity_uk` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `multi_select_choices`
--

DROP TABLE IF EXISTS `multi_select_choices`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `multi_select_choices` (
  `choice_id` bigint(20) NOT NULL,
  `choice_element` varchar(255) NOT NULL,
  `choice_position` int(11) NOT NULL,
  PRIMARY KEY (`choice_id`,`choice_position`),
  KEY `FKE4D1D6759E11278A` (`choice_id`),
  CONSTRAINT `FKE4D1D6759E11278A` FOREIGN KEY (`choice_id`) REFERENCES `parameter_vo` (`oid`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `multi_select_values`
--

DROP TABLE IF EXISTS `multi_select_values`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `multi_select_values` (
  `value_id` bigint(20) NOT NULL,
  `value_element` varchar(255) NOT NULL,
  `value_position` int(11) NOT NULL,
  PRIMARY KEY (`value_id`,`value_position`),
  KEY `FK8A82A13F176FA1BA` (`value_id`),
  CONSTRAINT `FK8A82A13F176FA1BA` FOREIGN KEY (`value_id`) REFERENCES `parameter_vo` (`oid`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `node`
--

DROP TABLE IF EXISTS `node`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `node` (
  `node_id` bigint(20) NOT NULL DEFAULT '0',
  `subclass` varchar(255) NOT NULL DEFAULT 'FileNode',
  `name` varchar(255) DEFAULT NULL,
  `node_owner` varchar(255) DEFAULT NULL,
  `task_id` bigint(20) DEFAULT NULL,
  `description` varchar(255) DEFAULT NULL,
  `visibility` varchar(255) DEFAULT NULL,
  `data_type` varchar(255) DEFAULT NULL,
  `length` bigint(20) DEFAULT NULL,
  `ord` int(11) DEFAULT NULL,
  `relative_session_path` varchar(255) DEFAULT NULL,
  `is_replicated` bit(1) DEFAULT NULL,
  `path_override` varchar(255) DEFAULT NULL,
  `blast_hit_count` bigint(20) DEFAULT NULL,
  `sequence_type` varchar(20) DEFAULT NULL,
  `sequence_count` int(11) DEFAULT NULL,
  `data_source_id` bigint(20) DEFAULT NULL,
  `decypher_db_id` varchar(255) DEFAULT NULL,
  `partition_count` int(11) NOT NULL DEFAULT '0',
  `is_Assembled_Data` bit(1) DEFAULT NULL,
  `num_hmms` int(11) NOT NULL DEFAULT '0',
  `user_id` bigint(20) DEFAULT NULL,
  PRIMARY KEY (`node_id`),
  UNIQUE KEY `decypher_db_id` (`decypher_db_id`),
  KEY `node_fk_data_source` (`data_source_id`),
  KEY `node_fk_user` (`user_id`),
  KEY `node_fk_task` (`task_id`),
  KEY `fk_subject_name2` (`node_owner`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `parameter_vo`
--

DROP TABLE IF EXISTS `parameter_vo`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `parameter_vo` (
  `oid` bigint(20) NOT NULL,
  `discriminator` varchar(255) NOT NULL,
  `boolean_value` bit(1) DEFAULT NULL,
  `double_min_value` double DEFAULT NULL,
  `double_max_value` double DEFAULT NULL,
  `double_value` double DEFAULT NULL,
  `long_min_value` bigint(20) DEFAULT NULL,
  `long_max_value` bigint(20) DEFAULT NULL,
  `long_value` bigint(20) DEFAULT NULL,
  `description` varchar(255) DEFAULT NULL,
  `text_max_length` int(11) DEFAULT NULL,
  `text_value` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`oid`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `project`
--

DROP TABLE IF EXISTS `project`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `project` (
  `symbol` varchar(255) NOT NULL,
  `description` text,
  `principal_investigators` varchar(255) DEFAULT NULL,
  `email` varchar(255) DEFAULT NULL,
  `organization` varchar(255) DEFAULT NULL,
  `website_url` varchar(255) DEFAULT NULL,
  `funded_by` varchar(255) DEFAULT NULL,
  `institutional_affiliation` varchar(255) DEFAULT NULL,
  `name` varchar(255) DEFAULT NULL,
  `released` bit(1) DEFAULT NULL,
  PRIMARY KEY (`symbol`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `project_publication_link`
--

DROP TABLE IF EXISTS `project_publication_link`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `project_publication_link` (
  `project_id` varchar(255) NOT NULL,
  `publication_id` bigint(20) NOT NULL,
  `position` int(11) NOT NULL,
  PRIMARY KEY (`project_id`,`position`),
  KEY `FK61B3CE93989D224C` (`publication_id`),
  KEY `FK61B3CE9363F6B82C` (`project_id`),
  CONSTRAINT `FK61B3CE9363F6B82C` FOREIGN KEY (`project_id`) REFERENCES `project` (`symbol`),
  CONSTRAINT `FK61B3CE93989D224C` FOREIGN KEY (`publication_id`) REFERENCES `publication` (`oid`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `publication`
--

DROP TABLE IF EXISTS `publication`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `publication` (
  `oid` bigint(20) NOT NULL,
  `publication_acc` varchar(50) DEFAULT NULL,
  `abstractOfPublication` text,
  `summary` text,
  `title` text,
  `subjectDocument` text,
  `supplemental_text` text,
  `pub_date` date DEFAULT NULL,
  `journal_entry` varchar(255) DEFAULT NULL,
  `description_html` text,
  PRIMARY KEY (`oid`),
  UNIQUE KEY `publication_acc` (`publication_acc`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `publication_author_link`
--

DROP TABLE IF EXISTS `publication_author_link`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `publication_author_link` (
  `publication_id` bigint(20) NOT NULL,
  `author_id` varchar(255) NOT NULL,
  `position` int(11) NOT NULL,
  PRIMARY KEY (`publication_id`,`position`),
  KEY `FKED48A49B989D224C` (`publication_id`),
  KEY `FKED48A49B3D48CE88` (`author_id`),
  CONSTRAINT `FKED48A49B3D48CE88` FOREIGN KEY (`author_id`) REFERENCES `author` (`name`),
  CONSTRAINT `FKED48A49B989D224C` FOREIGN KEY (`publication_id`) REFERENCES `publication` (`oid`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `publication_combined_archives_link`
--

DROP TABLE IF EXISTS `publication_combined_archives_link`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `publication_combined_archives_link` (
  `publication_id` bigint(20) NOT NULL,
  `data_file_id` bigint(20) NOT NULL,
  `position` int(11) NOT NULL,
  PRIMARY KEY (`publication_id`,`position`),
  KEY `FK95ED5B41989D224C` (`publication_id`),
  KEY `FK95ED5B419DDED49D` (`data_file_id`),
  CONSTRAINT `FK95ED5B41989D224C` FOREIGN KEY (`publication_id`) REFERENCES `publication` (`oid`),
  CONSTRAINT `FK95ED5B419DDED49D` FOREIGN KEY (`data_file_id`) REFERENCES `data_file` (`oid`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `publication_hierarchy_node_link`
--

DROP TABLE IF EXISTS `publication_hierarchy_node_link`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `publication_hierarchy_node_link` (
  `publication_id` bigint(20) NOT NULL,
  `hierarchy_node_id` bigint(20) NOT NULL,
  `position` int(11) NOT NULL,
  PRIMARY KEY (`publication_id`,`position`),
  KEY `FK12CD9BFA989D224C` (`publication_id`),
  KEY `FK12CD9BFAC973E5D7` (`hierarchy_node_id`),
  CONSTRAINT `FK12CD9BFA989D224C` FOREIGN KEY (`publication_id`) REFERENCES `publication` (`oid`),
  CONSTRAINT `FK12CD9BFAC973E5D7` FOREIGN KEY (`hierarchy_node_id`) REFERENCES `hierarchy_node` (`oid`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `read_assembly`
--

DROP TABLE IF EXISTS `read_assembly`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `read_assembly` (
  `scaffold_acc` varchar(255) NOT NULL,
  `read_acc` varchar(255) NOT NULL,
  `scaf_begin` int(11) DEFAULT NULL,
  `scaf_end` int(11) DEFAULT NULL,
  `scaf_orientation` int(11) DEFAULT NULL,
  `scaffold_length` int(11) DEFAULT NULL,
  `assembly_description` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`scaffold_acc`,`read_acc`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `read_mate`
--

DROP TABLE IF EXISTS `read_mate`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `read_mate` (
  `read_id` bigint(20) NOT NULL,
  `mate_id` bigint(20) NOT NULL,
  PRIMARY KEY (`read_id`,`mate_id`),
  KEY `FKBD9EF40EB84471E5` (`read_id`),
  KEY `FKBD9EF40EA9FE1A16` (`mate_id`),
  CONSTRAINT `FKBD9EF40EA9FE1A16` FOREIGN KEY (`mate_id`) REFERENCES `sequence_entity` (`entity_id`),
  CONSTRAINT `FKBD9EF40EB84471E5` FOREIGN KEY (`read_id`) REFERENCES `sequence_entity` (`entity_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `scality_objects`
--

DROP TABLE IF EXISTS `scality_objects`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `scality_objects` (
  `entity_data_id` bigint(20) NOT NULL,
  `parent_entity_id` bigint(20) DEFAULT NULL,
  `value` longtext,
  `creation_date` datetime DEFAULT NULL,
  `owner_key` varchar(64) NOT NULL,
  PRIMARY KEY (`entity_data_id`),
  KEY `so_parent_entity_id` (`parent_entity_id`),
  KEY `so_owner_key` (`owner_key`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `search_results`
--

DROP TABLE IF EXISTS `search_results`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `search_results` (
  `task_id` bigint(20) DEFAULT NULL,
  `node_id` bigint(20) DEFAULT NULL,
  `hit_id` bigint(20) DEFAULT NULL,
  `rank` bigint(20) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `sequence_entity`
--

DROP TABLE IF EXISTS `sequence_entity`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `sequence_entity` (
  `entity_id` bigint(20) NOT NULL,
  `entity_type_code` int(11) NOT NULL,
  `owner_id` bigint(20) DEFAULT NULL,
  `source_id` int(11) NOT NULL,
  `obs_flag` bit(1) NOT NULL,
  `replaced_by` varchar(255) DEFAULT NULL,
  `accession` varchar(255) DEFAULT NULL,
  `defline` varchar(255) DEFAULT NULL,
  `sequence_id` bigint(20) DEFAULT NULL,
  `sequence_length` int(11) DEFAULT NULL,
  `external_source` varchar(255) DEFAULT NULL,
  `external_acc` varchar(255) DEFAULT NULL,
  `ncbi_gi_number` int(11) DEFAULT NULL,
  `organism` varchar(255) DEFAULT NULL,
  `taxon_id` int(11) DEFAULT NULL,
  `assembly_acc` varchar(255) DEFAULT NULL,
  `assembly_id` bigint(20) DEFAULT NULL,
  `sample_acc` varchar(255) DEFAULT NULL,
  `sample_id` bigint(20) DEFAULT NULL,
  `library_acc` varchar(255) DEFAULT NULL,
  `library_id` bigint(20) DEFAULT NULL,
  `type` varchar(255) DEFAULT NULL,
  `trace_acc` varchar(255) DEFAULT NULL,
  `template_acc` varchar(255) DEFAULT NULL,
  `sequencing_direction` varchar(255) DEFAULT NULL,
  `clear_range_begin` int(11) DEFAULT NULL,
  `clear_range_end` int(11) DEFAULT NULL,
  `protein_acc` varchar(255) DEFAULT NULL,
  `protein_id` bigint(20) DEFAULT NULL,
  `dna_acc` varchar(255) DEFAULT NULL,
  `dna_id` bigint(20) DEFAULT NULL,
  `dna_begin` int(11) DEFAULT NULL,
  `dna_end` int(11) DEFAULT NULL,
  `dna_orientation` int(11) DEFAULT NULL,
  `translation_table` varchar(255) DEFAULT NULL,
  `stop_5_prime` varchar(255) DEFAULT NULL,
  `stop_3_prime` varchar(255) DEFAULT NULL,
  `orf_acc` varchar(255) DEFAULT NULL,
  `orf_id` bigint(20) DEFAULT NULL,
  PRIMARY KEY (`entity_id`),
  UNIQUE KEY `camera_acc` (`accession`),
  KEY `FKA23C5E21C964BBDE` (`entity_type_code`),
  KEY `FKA23C5E2164A5458F` (`orf_id`),
  KEY `FKA23C5E217F6AD893` (`library_id`),
  KEY `FKA23C5E2153897EBE` (`dna_id`),
  KEY `FKA23C5E21320BB9A1` (`sample_id`),
  KEY `FKA23C5E21B810A30F` (`protein_id`),
  KEY `FKA23C5E21E60408F7` (`sequence_id`),
  KEY `FKA23C5E217FAE6265` (`assembly_id`),
  KEY `FKA23C5E213EA50CFA` (`owner_id`),
  CONSTRAINT `FKA23C5E21320BB9A1` FOREIGN KEY (`sample_id`) REFERENCES `bio_sample` (`sample_id`),
  CONSTRAINT `FKA23C5E213EA50CFA` FOREIGN KEY (`owner_id`) REFERENCES `subject` (`id`),
  CONSTRAINT `FKA23C5E2153897EBE` FOREIGN KEY (`dna_id`) REFERENCES `sequence_entity` (`entity_id`),
  CONSTRAINT `FKA23C5E2164A5458F` FOREIGN KEY (`orf_id`) REFERENCES `sequence_entity` (`entity_id`),
  CONSTRAINT `FKA23C5E217F6AD893` FOREIGN KEY (`library_id`) REFERENCES `library` (`library_id`),
  CONSTRAINT `FKA23C5E217FAE6265` FOREIGN KEY (`assembly_id`) REFERENCES `assembly` (`assembly_id`),
  CONSTRAINT `FKA23C5E21B810A30F` FOREIGN KEY (`protein_id`) REFERENCES `sequence_entity` (`entity_id`),
  CONSTRAINT `FKA23C5E21C964BBDE` FOREIGN KEY (`entity_type_code`) REFERENCES `entity_type` (`code`),
  CONSTRAINT `FKA23C5E21E60408F7` FOREIGN KEY (`sequence_id`) REFERENCES `bio_sequence` (`sequence_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `sequence_type`
--

DROP TABLE IF EXISTS `sequence_type`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `sequence_type` (
  `code` int(11) NOT NULL,
  `name` varchar(255) NOT NULL,
  `description` varchar(255) NOT NULL,
  `elements` varchar(255) NOT NULL,
  `complements` varchar(255) NOT NULL,
  `residue_type` varchar(255) NOT NULL,
  PRIMARY KEY (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `single_select_values`
--

DROP TABLE IF EXISTS `single_select_values`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `single_select_values` (
  `value_id` bigint(20) NOT NULL,
  `value_element` varchar(255) NOT NULL,
  `position` int(11) NOT NULL,
  PRIMARY KEY (`value_id`,`position`),
  KEY `FKFA414A0EE27CCE23` (`value_id`),
  CONSTRAINT `FKFA414A0EE27CCE23` FOREIGN KEY (`value_id`) REFERENCES `parameter_vo` (`oid`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `subject`
--

DROP TABLE IF EXISTS `subject`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `subject` (
  `id` bigint(20) NOT NULL,
  `discriminator` varchar(64) NOT NULL,
  `subject_key` varchar(64) NOT NULL,
  `name` varchar(255) NOT NULL,
  `fullName` varchar(255) DEFAULT NULL,
  `email` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `subject_key` (`subject_key`),
  UNIQUE KEY `subject_name` (`name`),
  KEY `idx_subject_name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `subject_preference_map`
--

DROP TABLE IF EXISTS `subject_preference_map`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `subject_preference_map` (
  `user_id` bigint(20) NOT NULL,
  `name` varchar(255) DEFAULT NULL,
  `category` varchar(255) DEFAULT NULL,
  `value` varchar(255) DEFAULT NULL,
  `category_and_name` varchar(255) NOT NULL,
  PRIMARY KEY (`user_id`,`category_and_name`),
  KEY `fk_pref_user_idx` (`user_id`),
  CONSTRAINT `fk_pref_subject_id` FOREIGN KEY (`user_id`) REFERENCES `subject` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `subject_relationship`
--

DROP TABLE IF EXISTS `subject_relationship`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `subject_relationship` (
  `id` bigint(20) NOT NULL,
  `group_subject_id` bigint(20) NOT NULL,
  `user_subject_id` bigint(20) NOT NULL,
  `relationship_type` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `group_subject_id` (`group_subject_id`,`user_subject_id`),
  KEY `fk_group_subject_id` (`group_subject_id`),
  KEY `fk_user_subject_id` (`user_subject_id`),
  CONSTRAINT `fk_group_subject_id` FOREIGN KEY (`group_subject_id`) REFERENCES `subject` (`id`),
  CONSTRAINT `fk_user_subject_id` FOREIGN KEY (`user_subject_id`) REFERENCES `subject` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `task`
--

DROP TABLE IF EXISTS `task`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `task` (
  `task_id` bigint(20) NOT NULL,
  `subclass` varchar(255) NOT NULL,
  `parent_task_id` bigint(20) DEFAULT NULL,
  `task_name` varchar(255) NOT NULL,
  `task_owner` varchar(255) NOT NULL,
  `job_name` varchar(255) DEFAULT NULL,
  `task_deleted_flag` bit(1) DEFAULT NULL,
  `expiration_date` date DEFAULT NULL,
  `task_note` varchar(255) DEFAULT NULL,
  `user_id` bigint(20) DEFAULT NULL,
  PRIMARY KEY (`task_id`),
  KEY `task_fk_user` (`user_id`),
  KEY `fk_subject_name` (`task_owner`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `task_event`
--

DROP TABLE IF EXISTS `task_event`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `task_event` (
  `task_id` bigint(20) NOT NULL,
  `event_no` int(11) NOT NULL,
  `description` text,
  `event_timestamp` datetime NOT NULL,
  `event_type` varchar(255) NOT NULL,
  PRIMARY KEY (`task_id`,`event_no`),
  KEY `task_event_fk_task` (`task_id`),
  KEY `task_event_event_type` (`event_type`),
  CONSTRAINT `task_event_fk_task` FOREIGN KEY (`task_id`) REFERENCES `task` (`task_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `task_input_node`
--

DROP TABLE IF EXISTS `task_input_node`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `task_input_node` (
  `task_id` bigint(20) NOT NULL,
  `node_id` bigint(20) NOT NULL,
  PRIMARY KEY (`task_id`,`node_id`),
  KEY `task_input_node_fk_node` (`node_id`),
  KEY `task_input_node_fk_task` (`task_id`),
  CONSTRAINT `task_input_node_fk_task` FOREIGN KEY (`task_id`) REFERENCES `task` (`task_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `task_message`
--

DROP TABLE IF EXISTS `task_message`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `task_message` (
  `message_id` bigint(20) NOT NULL,
  `message` text NOT NULL,
  `task_id` bigint(20) DEFAULT NULL,
  PRIMARY KEY (`message_id`),
  KEY `FK6239874D1233B4B2` (`task_id`),
  CONSTRAINT `FK6239874D1233B4B2` FOREIGN KEY (`task_id`) REFERENCES `task` (`task_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `task_parameter`
--

DROP TABLE IF EXISTS `task_parameter`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `task_parameter` (
  `task_id` bigint(20) NOT NULL,
  `parameter_name` varchar(255) NOT NULL,
  `parameter_value` text,
  PRIMARY KEY (`task_id`,`parameter_name`),
  KEY `task_parameters_clob_fk_task` (`task_id`),
  KEY `pvclob_index` (`parameter_value`(255)),
  CONSTRAINT `task_parameters_clob_fk_task` FOREIGN KEY (`task_id`) REFERENCES `task` (`task_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `task_parameter_bak`
--

DROP TABLE IF EXISTS `task_parameter_bak`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `task_parameter_bak` (
  `task_id` bigint(20) NOT NULL,
  `parameter_name` varchar(255) NOT NULL,
  `parameter_value` varchar(10000) DEFAULT NULL,
  PRIMARY KEY (`task_id`,`parameter_name`),
  KEY `task_parameters_fk_task` (`task_id`),
  KEY `pv_index` (`parameter_value`(255)),
  CONSTRAINT `task_parameters_fk_task` FOREIGN KEY (`task_id`) REFERENCES `task` (`task_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `tmNeuron`
--

DROP TABLE IF EXISTS `tmNeuron`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tmNeuron` (
  `id` bigint(20) NOT NULL,
  `tm_workspace_id` bigint(20) NOT NULL,
  `protobuf_value` longblob NOT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_tmn_workspace_id` (`tm_workspace_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `tool_activity`
--

DROP TABLE IF EXISTS `tool_activity`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tool_activity` (
  `id` bigint(20) NOT NULL,
  `session_id` bigint(20) DEFAULT NULL,
  `user_login` varchar(40) NOT NULL,
  `tool_name` varchar(20) NOT NULL,
  `category` varchar(200) DEFAULT NULL,
  `action` varchar(4000) NOT NULL,
  `event_time` datetime(3) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `tool_activity_fk1` (`user_login`),
  KEY `tool_activity_user_login` (`user_login`),
  KEY `tool_activity_category` (`category`),
  KEY `tool_activity_tool_name` (`tool_name`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Final view structure for view `TAC_FOLDER_ID_LOAD_ID`
--

/*!50001 DROP TABLE IF EXISTS `TAC_FOLDER_ID_LOAD_ID`*/;
/*!50001 DROP VIEW IF EXISTS `TAC_FOLDER_ID_LOAD_ID`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8 */;
/*!50001 SET character_set_results     = utf8 */;
/*!50001 SET collation_connection      = utf8_general_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`flyportalAdmin`@`%` SQL SECURITY DEFINER */
/*!50001 VIEW `TAC_FOLDER_ID_LOAD_ID` AS (select substr(`tool_activity`.`action`,(locate(':',`tool_activity`.`action`) + 1)) AS `folder`,substr(`tool_activity`.`action`,1,(locate(':',`tool_activity`.`action`) - 1)) AS `folder_id`,`tool_activity`.`id` AS `load_tile_id` from `tool_activity` where (`tool_activity`.`category` = 'loadTileTiffToRam')) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `TAC_FOLDER_ID_PATH`
--

/*!50001 DROP TABLE IF EXISTS `TAC_FOLDER_ID_PATH`*/;
/*!50001 DROP VIEW IF EXISTS `TAC_FOLDER_ID_PATH`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8 */;
/*!50001 SET character_set_results     = utf8 */;
/*!50001 SET collation_connection      = utf8_general_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`flyportalAdmin`@`%` SQL SECURITY DEFINER */
/*!50001 VIEW `TAC_FOLDER_ID_PATH` AS (select substr(`tool_activity`.`action`,(locate(':',`tool_activity`.`action`) + 1)) AS `folder_id`,substr(`tool_activity`.`action`,1,(locate(':',`tool_activity`.`action`) - 1)) AS `folder` from `tool_activity` where (`tool_activity`.`category` = 'openWholeTifFolder')) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2018-11-09 11:48:16
