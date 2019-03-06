Description
===========

Custom Docker image for the XWiki project, used to spawn Jenkins Agents for https://ci.xwiki.org.

This image adds the following XWiki-required build tools over the 
[`jenkins/ssh-slave`](https://hub.docker.com/r/jenkinsci/ssh-slave) base image provided by Jenkins:
* VNC Server
* Docker Client (to run our Docker-based tests)
* Recent Java 8 version (Amazon Corretto)
* Firefox 32.0.1 (for running our Selenium-2 based functional tests)

This image is built automatically by 
[Dockerhub](https://cloud.docker.com/u/xwiki/repository/docker/xwiki/xwiki-jenkins-slave).

Local Usage
===========

It can be useful to be able to reproduce a CI issue locally on your machine.

On Mac
------

The following steps show how to run the image and have the GUI be displayed on your Mac (follow this 
[tutorial](https://cntnr.io/running-guis-with-docker-on-mac-os-x-a14df6a76efc) to install the right tools).

```
socat TCP-LISTEN:6000,reuseaddr,fork UNIX-CLIENT:\"$DISPLAY\"
open -a Xquartz
IP=$(ifconfig en0 | grep inet | awk '$1=="inet" {print $2}')
docker run -d --rm -v /var/run/docker.sock:/var/run/docker.sock -v $HOME/.m2:/root/.m2:delegated -v $HOME/dev/xwiki/xwiki-platform:/root/xwiki-platform:delegated -e DISPLAY=$IP:0 --privileged xwiki-jenkins-slave
```

Explanations:
* First 3 lines are to be able to display the GUI on your mac
* For the `docker run` command:
  * The `delegated` parts are to try to speed up the volume mounting since that's 
  [very slow on Mac](https://docs.docker.com/docker-for-mac/osxfs-caching/).
  * The `-v /var/run/docker.sock:/var/run/docker.sock` is for running Docker in Docker
  * The `-v $HOME/.m2:/root/.m2:delegated` is to avoid redownloading all dependencies by reusing your local Maven repo
  * Similarly the `-v $HOME/dev/xwiki/xwiki-platform:/root/xwiki-platform:delegated` is to avoid having to clone the
  XWiki Platform GitHub repository
  * The `-e DISPLAY=$IP:0` is to forward the display to your Mac.
  * The `--privileged` is because... not sure why but it might be required for some cases ;)

