Description
===========

Custom Docker image for the XWiki Android applications, used to spawn Jenkins Agents for https://ci.xwiki.org.

This image adds the following over the 
[`xwiki/build`](https://hub.docker.com/r/xwiki/build) base image:
* Android SDK 28 and 29
* XWiki Platform Jetty HSQLDB 10.11.10 (current LTS)

This image is built automatically by 
[Dockerhub](https://hub.docker.com/r/xwiki/build-android).

CI / Local Usage
========

See documentation from [base image](../build). 

Running XWiki Platform from the container
======== 

A version of XWiki Platform is automatically deployed when the image is built in order to perform Android integration test while using a real instance of XWiki.
This instance is available in `/opt/xwiki-lts`, so it's possible to call the commands using this absolute path, for example:
```
$ /opt/xwiki-lts/start_xwiki.sh -p 8080 -sp 8079
```
