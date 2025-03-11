CREATE TABLE profiles (profile VARCHAR(64), username VARCHAR(128),\
    password VARCHAR(255), domain VARCHAR(255), exts TEXT, ignore_exts \
    VARCHAR(10), dirs TEXT, ignore_dirs VARCHAR(10), regex TEXT, path TINYTEXT,\
    phonehomeurl VARCHAR(255), phonehomeuser VARCHAR(32), phonehomepass \
    VARCHAR(32), delaytime SMALLINT UNSIGNED, description VARCHAR(128), \
    debug SMALLINT UNSIGNED, number SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT, \
    primary key (number), concurrent SMALLINT UNSIGNED, creditcards TEXT, \
    zipfiles TEXT, memory FLOAT, mask BOOL, hash VARCHAR(65), ignore_dbs \
    VARCHAR(10), dbs TEXT, ignore_tables VARCHAR(10), tables TEXT, \
    ignore_columns VARCHAR(10), columns TEXT, rows BIGINT, scantype \
    VARCHAR(20), metaport bigint(20) unsigned, metalatency bigint(20) unsigned,\
    metauser varchar(65), metapass varchar(65), metapath varchar(255), \
    metatimeout int(11), metassl tinyint(1));
CREATE TABLE systems (scan VARCHAR(64), system VARCHAR(255), domain\
    VARCHAR(255), ip VARCHAR(40), filestotal INT, filesdone INT, bytestotal\
    BIGINT, bytesdone BIGINT, status VARCHAR(10), updated VARCHAR(12), \
    tracker VARCHAR(32), profile VARCHAR(64), control VARCHAR(16), pid \
    SMALLINT UNSIGNED, dbtotal INT, dbdone INT, tabletotal INT, tabledone INT, \
    columntotal INT, columndone INT, scantype VARCHAR(20), sessionid \
    varchar(65));
CREATE TABLE results (scan VARCHAR(64), system VARCHAR(64), domain \
    VARCHAR(255), type VARCHAR(64), pattern VARCHAR(255), file VARCHAR(8096),\
    offset BIGINT UNSIGNED, md5 VARCHAR(32), tracker VARCHAR(32), number \
    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT, primary key (number), is_false \
    TINYINT, db VARCHAR(256), tbl VARCHAR(256), col VARCHAR(256), row BIGINT \
    UNSIGNED);
CREATE TABLE regexes (name VARCHAR(64), pattern TEXT, number \
    SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT, primary key (number));
CREATE TABLE falsepositives (scan VARCHAR(64), tracker VARCHAR(32), \
    domain VARCHAR(255), type VARCHAR(64), file VARCHAR(8096), offset BIGINT \
    UNSIGNED, md5 VARCHAR(32));
CREATE TABLE logs (tracker VARCHAR(32), line INT UNSIGNED, data \
    VARCHAR(255), updated VARCHAR(18), scan VARCHAR(64), profile VARCHAR(64));
create table agentless (tracker varchar(32), scan varchar(64), file \
    varchar(8096));
create table agentless_zip (tracker varchar(32), scan varchar(64), \
    unzipdir varchar(64));
create table agentless_mount (tracker varchar(32), scan varchar(64),\
    mountdir varchar(64));
