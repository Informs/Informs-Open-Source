-- phpMyAdmin SQL Dump
-- version 2.8.1
-- http://www.phpmyadmin.net
-- 
-- Host: localhost
-- Generation Time: Oct 21, 2011 at 10:12 AM
-- Server version: 5.0.67
-- PHP Version: 5.2.4
-- 
-- Database: 'informs'
-- 
CREATE DATABASE informs DEFAULT CHARACTER SET latin1 COLLATE latin1_swedish_ci;
USE informs;

-- --------------------------------------------------------

-- 
-- Table structure for table 'accounts'
-- 

CREATE TABLE accounts (
  account int(10) unsigned NOT NULL auto_increment,
  title tinytext NOT NULL,
  contactInfo text,
  logo tinytext,
  css tinytext,
  PRIMARY KEY  (account)
) ENGINE=MyISAM AUTO_INCREMENT=440 DEFAULT CHARSET=latin1;

-- 
-- Dumping data for table 'accounts'
-- 

INSERT INTO accounts (account, title, contactInfo, logo, css) VALUES (1, 'Superadmin', NULL, NULL, NULL);

-- --------------------------------------------------------

-- 
-- Table structure for table 'audit'
-- 

CREATE TABLE audit (
  event bigint(20) unsigned NOT NULL auto_increment,
  id int(10) unsigned NOT NULL default '0',
  `user` int(10) unsigned NOT NULL default '0',
  account int(10) unsigned default NULL,
  `timeStamp` int(10) unsigned NOT NULL default '0',
  ip varchar(15) default NULL,
  `type` char(1) default NULL,
  eventText text,
  PRIMARY KEY  (event)
) ENGINE=MyISAM AUTO_INCREMENT=224916 DEFAULT CHARSET=latin1;

-- 
-- Dumping data for table 'audit'
-- 


-- --------------------------------------------------------

-- 
-- Table structure for table 'objects'
-- 

CREATE TABLE objects (
  object int(10) unsigned NOT NULL auto_increment,
  filename tinytext NOT NULL,
  description tinytext,
  filetype char(3) NOT NULL default '',
  creationTimeStamp int(10) unsigned NOT NULL default '0',
  owner int(10) unsigned NOT NULL default '0',
  encoding tinytext,
  deleted int(10) unsigned default NULL,
  readonly tinyint(4) default NULL,
  PRIMARY KEY  (object),
  KEY filename (filename(100)),
  KEY filetype (filetype)
) ENGINE=MyISAM AUTO_INCREMENT=148160 DEFAULT CHARSET=latin1;

-- 
-- Dumping data for table 'objects'
-- 


-- --------------------------------------------------------

-- 
-- Table structure for table 'portfolios'
-- 

CREATE TABLE portfolios (
  portfolio int(10) unsigned NOT NULL auto_increment,
  title tinytext NOT NULL,
  account int(10) unsigned default NULL,
  parent int(10) unsigned default NULL,
  PRIMARY KEY  (portfolio),
  KEY title (title(255)),
  KEY account (account),
  KEY parent (parent)
) ENGINE=MyISAM AUTO_INCREMENT=685 DEFAULT CHARSET=latin1;

-- 
-- Dumping data for table 'portfolios'
-- 

INSERT INTO portfolios (portfolio, title, account, parent) VALUES (1, 'Superadmin', 1, 0);

-- --------------------------------------------------------

-- 
-- Table structure for table 'portfoliousers'
-- 

CREATE TABLE portfoliousers (
  portfolio int(11) unsigned NOT NULL default '0',
  `user` int(11) unsigned NOT NULL default '0',
  PRIMARY KEY  (portfolio,`user`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

-- 
-- Dumping data for table 'portfoliousers'
-- 


-- --------------------------------------------------------

-- 
-- Table structure for table 'sessions'
-- 

CREATE TABLE sessions (
  `user` int(10) unsigned default NULL,
  account int(10) unsigned default NULL,
  `session` char(32) NOT NULL default '',
  `timestamp` int(10) unsigned default NULL,
  autologin tinyint(3) unsigned default NULL,
  ip char(15) default NULL,
  PRIMARY KEY  (`session`),
  KEY `user` (`user`),
  KEY account (account)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

-- 
-- Dumping data for table 'sessions'
-- 


-- --------------------------------------------------------

-- 
-- Table structure for table 'stats'
-- 

CREATE TABLE stats (
  `time` int(10) unsigned default NULL,
  `session` bigint(20) unsigned default NULL,
  unit int(10) unsigned default NULL,
  step smallint(5) unsigned default NULL,
  total smallint(5) unsigned default NULL,
  KEY `time` (`time`),
  KEY `session` (`session`),
  KEY unit (unit)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

-- 
-- Dumping data for table 'stats'
-- 


-- --------------------------------------------------------

-- 
-- Table structure for table 'statslookup'
-- 

CREATE TABLE statslookup (
  sessionNumber bigint(20) unsigned NOT NULL auto_increment,
  sessionID char(32) NOT NULL default '',
  `time` int(10) unsigned default NULL,
  PRIMARY KEY  (sessionID),
  UNIQUE KEY sessionNumber (sessionNumber)
) ENGINE=MyISAM AUTO_INCREMENT=3081003 DEFAULT CHARSET=latin1;

-- 
-- Dumping data for table 'statslookup'
-- 


-- --------------------------------------------------------

-- 
-- Table structure for table 'steps'
-- 

CREATE TABLE steps (
  unit int(10) unsigned NOT NULL default '0',
  step int(10) unsigned NOT NULL default '0',
  leftFrame int(10) unsigned default NULL,
  rightFrame int(10) unsigned default NULL,
  url text,
  toc tinytext,
  PRIMARY KEY  (unit,step)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

-- 
-- Dumping data for table 'steps'
-- 


-- --------------------------------------------------------

-- 
-- Table structure for table 'units'
-- 

CREATE TABLE units (
  unit int(10) unsigned NOT NULL auto_increment,
  title tinytext NOT NULL,
  description text NOT NULL,
  portfolio int(10) unsigned NOT NULL default '0',
  visible char(1) default NULL,
  displayOrder smallint(5) unsigned default NULL,
  openMethod varchar(15) default NULL,
  stylesheet text,
  `date` date default '0000-00-00',
  last_edited date default NULL,
  PRIMARY KEY  (unit),
  KEY portfolio (portfolio),
  KEY title (title(100)),
  KEY last_edited (last_edited)
) ENGINE=MyISAM AUTO_INCREMENT=6353 DEFAULT CHARSET=latin1;

-- 
-- Dumping data for table 'units'
-- 


-- --------------------------------------------------------

-- 
-- Table structure for table 'unitscopied'
-- 

CREATE TABLE unitscopied (
  id int(9) unsigned NOT NULL auto_increment,
  newunitid int(9) unsigned default NULL,
  originalunitid int(9) unsigned default NULL,
  fromportfolio int(9) unsigned default NULL,
  toportfolio int(9) unsigned default NULL,
  account int(11) unsigned default NULL,
  `timestamp` int(11) unsigned default NULL,
  PRIMARY KEY  (id)
) ENGINE=MyISAM AUTO_INCREMENT=655980 DEFAULT CHARSET=latin1;

-- 
-- Dumping data for table 'unitscopied'
-- 


-- --------------------------------------------------------

-- 
-- Table structure for table 'users'
-- 

CREATE TABLE users (
  `user` int(10) unsigned NOT NULL auto_increment,
  username varchar(32) NOT NULL default '',
  `password` varchar(32) NOT NULL default '',
  account int(11) unsigned NOT NULL default '0',
  email tinytext,
  role varchar(12) NOT NULL default '',
  `name` tinytext NOT NULL,
  PRIMARY KEY  (`user`),
  KEY account (account)
) ENGINE=MyISAM AUTO_INCREMENT=1117 DEFAULT CHARSET=latin1;

-- 
-- Dumping data for table 'users'
-- 

INSERT INTO users (user, username, password, account, email, role, name) VALUES (1, 'superadmin', 'super123', 1, NULL, 'superadmin', 'superadmin');
