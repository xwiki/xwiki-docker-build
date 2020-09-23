Description
===========

A custom Oracle Database 19.3.0 Standard Edition image to test XWiki on Oracle. The image is custom for the following reasons:
* The [official Oracle Database image](https://github.com/oracle/docker-images/tree/master/OracleDatabase/SingleInstance/dockerfiles/19.3.0) takes about 45 minutes to start when it's first run as a container. This image takes 3-4 minutes 
* This image has the XWIKI user created with proper permissions and proper tablespace size. It's ready to be used for XWiki. 

Usage
=====

```
docker run -p 1521:1521 -p 5500:5500 xwiki/oracle-database:19.3.0-se2
```

Building
========

Note that the strategy followed to build this image is the one described in [this article](https://medium.com/@ggajos/drop-db-startup-time-from-45-to-3-minutes-in-dockerized-oracle-19-3-0-552068593deb)

The following custom steps were followed:
* Run the official image:
  ```
  docker run -p 1521:1521 -p 5500:5500 -e ORACLE_SID=XWIKICDB -e ORACLE_PDB=XWIKI -e ORACLE_PWD=xwiki oracle/database:19.3.0-se2
  ```
* Get a shell into it:
  ```
  docker exec -it <containerid> bash -l
  ```  
* Increase the max number of processes to 500 (default was 150), to avoid `ORA-12516, TNS:listener could not find available handler with matching protocol stack` errors:

  Execute PL/SQL to log into the CDB as SYSDBA since the process increase needs to be executed in the CDB (doesn't work in the PDB):
  ```
  sqlplus sys/xwiki@//localhost:1521/XWIKICDB as sysdba
  ```
  
  Increase the processes:
  ```
  alter system set PROCESSES=500 scope = spfile;
  ```  
* Execute PL/SQL to log into the XWiki PDB as SYSTEM for the following instructions:
  ```
  sqlplus system/xwiki@//localhost:1521/XWIKI
  ```
* Give more space to the default USERS tablespace used by the `XWIKI` user:
  ```
  alter database datafile '/opt/oracle/oradata/XWIKICDB/XWIKI/users01.dbf' resize 100M;
  ```
* Increase max open cursors to 3000 (default was 300), to avoid `ORA-01000: maximum open cursors exceeded` errors:
  ```
  alter system set open_cursors = 3000 scope=both;
  ```
* Create the XWiki user:

  Make sure that the user password won't expire (by default it exires after 180 days): 
  ```
  alter profile "DEFAULT" limit password_life_time unlimited;
  ```
    
  Create the user and set permissions and make sure that the `XWIKI` user has all quotas on the `USERS` tablespace:
  ```
  create user xwiki identified by xwiki;
  grant connect to xwiki;
  grant resource to xwiki;
  grant dba to xwiki;
  alter user xwiki quota unlimited on users;
  ```
* Save the modified image:
  ```
  docker commit --author 'XWiki Dev Team <committers@xwiki.org>' --message "Test snapshot for CI" <containerid> xwiki/oracle-database:19.3.0-se2
  ``` 
* Push to DockerHub:
  ```
  docker push xwiki/oracle-database:19.3.0-se2
  ```
