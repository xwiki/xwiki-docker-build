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
  docker run -p 1521:1521 -p 5500:5500 -e ORACLE_SID=xwiki -e ORACLE_PDB=xwikipdb -e ORACLE_PWD=xwiki  oracle/database:19.3.0-se2
  ```
* Get a shell into it:
  ```
  docker exec -it <containerid> bash -l
  ```  
* Execute PL/SQL:
  ```
  sqlplus sys/xwiki@//localhost:1521/xwiki as sysdba
  ```
* Give more space to the default tablespace for the `XWIKI` DB:
  ```
  alter database datafile '/opt/oracle/oradata/XWIKI/users01.dbf' resize 100M;
  ```
* Create the XWiki user:

  Make sure that the user password won't expire (by default it exires after 180 days): 
  ```
  alter profile "DEFAULT" limit password_life_time unlimited;
  ```
  
  Allows creating a simple user named `XWIKI`. Without this Oracle will forbid the usage of such a simple name:
  ```
  alter session set "_ORACLE_SCRIPT"=true;
  ```
  
  Create the user and permissions:
  ```
  create user xwiki identified by xwiki;
  grant connect to xwiki;
  grant resource to xwiki;
  grant dba to xwiki;
  ```
* Save the modified image:
  ```
  docker commit --author 'XWiki Dev Team <committers@xwiki.org>' --message "Test snapshot for CI" <containerid> xwiki/oracle-database:19.3.0-se2
  ``` 
* Push to DockerHub:
  ```
  docker push xwiki/oracle-database:19.3.0-se2
  ```
