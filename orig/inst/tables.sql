-- MySQL dump 9.09
--
-- Host: localhost    Database: rcats
-- ------------------------------------------------------
-- Server version	4.0.16

--
-- Table structure for table `user`
--

CREATE TABLE user (
  id bigint(15) unsigned default NULL,
  username char(32) default NULL,
  password char(32) default NULL,
  cathome bigint(15) default NULL,
  notify_ok char(1) default 'N',
  acl char(4) default NULL,
  catlast bigint(15) default NULL
) TYPE=MyISAM;

--
-- Table structure for table `useremails`
--

CREATE TABLE useremails (
  email char(64) default NULL,
  id bigint(15) default NULL
) TYPE=MyISAM;

--

CREATE TABLE usershells (
  loginname char(16) default NULL,
  id bigint(15) default NULL
) TYPE=MyISAM;



--
-- Table structure for table `views`
--

CREATE TABLE views (
  uid bigint(10) default NULL,
  data_source char(64) default NULL,
  method char(64) default NULL,
  template_file char(128) default NULL
) TYPE=MyISAM;

--
-- Table structure for table `viewprefs`
--

CREATE TABLE viewprefs (
  cid bigint(20) default NULL,
  id bigint(20) default NULL,
  userid bigint(20) default NULL,
  viewid bigint(10) default NULL,
  pagetype char(32) default NULL
) TYPE=MyISAM;


--
-- Table structure for table `person`
--

CREATE TABLE person (
  id bigint(15) unsigned NOT NULL default '0',
  propername varchar(64) default NULL,
  email varchar(64) default NULL,
  phone varchar(16) default NULL,
  cellphone varchar(16) default NULL,
  fax varchar(16) default NULL,
  address1 varchar(128) default NULL,
  address2 varchar(128) default NULL,
  city varchar(64) default NULL,
  state varchar(64) default NULL,
  zip varchar(16) default NULL,
  acl varchar(4) default NULL,
  KEY index_1 (id)
) TYPE=MyISAM;



-- MySQL dump 9.09
--
-- Host: localhost    Database: rcats
-- ------------------------------------------------------
-- Server version	4.0.16

--
-- Table structure for table `content`
--

CREATE TABLE content (
  id bigint(15) unsigned NOT NULL default '0',
  content blob,
  type varchar(16) default NULL,
  acl varchar(4) default NULL,
  KEY index_1 (id)
) TYPE=MyISAM;

--
-- Table structure for table `longcontent`
--

CREATE TABLE longcontent (
  id bigint(15) unsigned default NULL,
  content mediumblob,
  acl varchar(4) default NULL
) TYPE=MyISAM;


--
-- Table structure for table `relatedcontent`
--

CREATE TABLE relatedcontent (
  uid bigint(15) default NULL,
  text blob,
  acl varchar(4) default NULL
) TYPE=MyISAM;

--
-- Table structure for table `handles`
--

CREATE TABLE handles (
  id bigint(20) default NULL,
  userid bigint(20) default NULL,
  handle char(32) default NULL,
  type char(1) default NULL,
  groupid bigint(20) default NULL,
  catid bigint(15) default NULL,
  KEY handle (handle,userid)
) TYPE=MyISAM;

--
-- Table structure for table `metadata`
--

CREATE TABLE metadata (
  id bigint(15) unsigned NOT NULL default '0',
  title varchar(128) default NULL,
  keywords blob,
  description blob,
  author varchar(64) default NULL,
  KEY index_1 (id)
) TYPE=MyISAM;


