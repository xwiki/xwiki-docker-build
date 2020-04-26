# Description

Custom Docker image for the XWiki project, used to spawn Jenkins Agents for https://ci.xwiki.org but can also he used to build XWiki on any machine having Docker installed.

This image adds the following XWiki-required build tools over the 
[`jenkins/ssh-slave`](https://hub.docker.com/r/jenkinsci/ssh-slave) base image provided by Jenkins:
* VNC Server
* Docker Client (to run our Docker-based tests)
* Recent Java 8 version (Amazon Corretto)
* Firefox 32.0.1 (for running our Selenium-2 based functional tests) + newer version of Firefox (for running our Selenium-3 based functional tests that are not yet Docker tests)

This image is built automatically by 
[Dockerhub](https://hub.docker.com/r/xwiki/build).

# CI Usage

## Setup for ci.xwiki.org

* Make sure that the following exist on the agent machine (see the explanations below for more details):
  * `/home/hudsonagent/.m2/settings.xml`
  * `/home/hudsonagent/.ssh`
* Configure a Docker cloud
  * Docker host URI: `tcp:/<ip of agent host>:2376`
  * Image: `xwiki/build`
  * Volumes: 
     ```
     /var/run/docker.sock:/var/run/docker.sock
     /home/hudsonagent/.m2/settings.xml:/root/.m2/settings.xml
     /home/hudsonagent/.ssh:/tmp/xwiki/.ssh:ro
     ```
     Explanations:
       * `/var/run/docker.sock:/var/run/docker.sock`: to allow Docker out of Docker (DOOD) and be able to use Docker 
         containers for our functional tests.
       * `/home/hudsonagent/.m2/settings.xml:/root/.m2/settings.xml`: To allow `mvn deploy` to work so that it can
         deploy built artifacts to nexus.xwiki.org.
       * `/home/hudsonagent/.ssh:/tmp/xwiki/.ssh:ro`: To allow some Jenkins pipeline (such as the Clover one) to 
         publish output to some other machines in the network (such as publishing clover zip reports to `maven.xwiki.org`).  
  * Remote File System Root: `/root`
  * User: `root`

## Manual execution on CI agent

If you wish to log on a CI agent to reproduce a problem and manually execute a build you can do the following:
* Ssh to the agent
* Start the docker agent with `docker run -d --rm -v /var/run/docker.sock:/var/run/docker.sock -v /home/hudsonagent/.m2/settings.xml:/root/.m2/settings.xml -v /home/hudsonagent/.ssh:/tmp/xwiki/.ssh:ro xwiki/build`
* Get a shell inside the docker container with `docker exec -it <container id> bash -l`
* Git clone a repo, for example: `git clone https://github.com/xwiki/xwiki-platform.git`
* Run a Maven build, for example: `cd xwiki-platform/<some path>; mvn clean install`
  * Docker test example: In `~/xwiki-platform/xwiki-platform-core/xwiki-platform-annotation/xwiki-platform-annotation-test/xwiki-platform-annotation-test-docker`, run `mvn clean integration-test -Dxwiki.checkstyle.skip=true -Dxwiki.surefire.captureconsole.skip=true -Dxwiki.revapi.skip=true -Dmaven.build.dir=target/mysql-5.7-5.1.45-tomcat-8.5-chrome -Dxwiki.test.ui.database=mysql -Dxwiki.test.ui.databaseTag=5.7 -Dxwiki.test.ui.jdbcVersion=5.1.45 -Dxwiki.test.ui.servletEngine=tomcat -Dxwiki.test.ui.servletEngineTag=8.5 -Dxwiki.test.ui.browser=chrome -Dxwiki.test.ui.verbose=true`
* If your build requires VNC, you can start a VNC server with `vncserver :1 -geometry 1280x960 -localhost -nolisten tcp` and set the `DISPLAY` with `export DISPLAY=:1`.
* Stop the container once you're done with `docker stop <container id>`

# Local Usage

It can be useful to be able to reproduce a CI issue locally on your machine or simply as a simple environment to build XWiki locally (all that is need is Docker installed).

## For all OSes

### Interactive mode

If you want the minimal build setup and have something the most similar to what executes on the CI agents, you can run:

```bash
docker run --rm -it -v /var/run/docker.sock:/var/run/docker.sock --entrypoint "/bin/bash" xwiki/build
```

Then:
* Git clone the repo to build, for example: `git clone https://github.com/xwiki/xwiki-platform.git`
* Navigate to the directory you wish to build and issue the maven command

Notes:
* If you want to map your machine's local Maven repository or other options, see below.
* If you run some Selenium2-based functional tests they require a DISPLAY. See below.
  * Otherwise you'll get some failure such as `Caused by: org.openqa.selenium.WebDriverException: invalid argument: can't kill an exited process`.

### Scripted mode

If you want to execute everything in one go, here's an example that overrides the entry point and build the whole XWiki Platform (including functional tests):

```bash
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock --entrypoint "/bin/bash" xwiki/build -c " \
git clone https://github.com/xwiki/xwiki-platform.git && \
cd xwiki-platform && \
export MAVEN_OPTS='-Xmx2048m -Xms512m' && \
vncserver :1 -geometry 1280x960 -localhost -nolisten tcp && \
export DISPLAY=:1 && \
/home/hudsonagent/maven/bin/mvn --no-transfer-progress install -Plegacy,integration-tests,docker,snapshot \
"
```

## On Mac

The following steps show how to run the image and have the GUI be displayed on your Mac (follow this 
[tutorial](https://cntnr.io/running-guis-with-docker-on-mac-os-x-a14df6a76efc) to install the right tools).

```bash
socat TCP-LISTEN:6000,reuseaddr,fork UNIX-CLIENT:\"$DISPLAY\"
open -a Xquartz
IP=$(ifconfig en0 | grep inet | awk '$1=="inet" {print $2}')

cd ...navigate locally in the maven module with the pom.xml to build...

docker run -d --rm \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v $HOME/.m2:/root/.m2:delegated \
  -v $HOME/.git-credentials:/root/.git-credentials \
  -v $HOME/.git-gitconfig:/root/.git-gitconfig \
  -v $HOME/.gitconfig:/root/.gitconfig \
  -v $HOME/.gitignore_global:/root/.gitignore_global \
  -v $HOME/.ssh:/tmp/xwiki/.ssh:ro \
  -v $HOME/.gnupg:/root/.gnupg \
  -v `pwd`:/root/`basename \`pwd\``:delegated \
  -e DISPLAY=$IP:0 -p 8080:8080 --privileged xwiki/build
```

Explanations:
* First 3 lines are to be able to display the GUI on your mac
* For the `docker run` command:
  * The `delegated` parts are to try to speed up the volume mounting since that's 
  [very slow on Mac](https://docs.docker.com/docker-for-mac/osxfs-caching/).
  * The `-v /var/run/docker.sock:/var/run/docker.sock` is for running Docker in Docker
  * The `-v $HOME/.m2:/root/.m2:delegated` is to avoid redownloading all dependencies by reusing your local Maven repo
  * The `.git*` volume mappings are to have your Git config inside the container
  * The `-v $HOME/.ssh:/tmp/xwiki/.ssh:ro` is to have your SSH keys inside the container (there's an entry script that will copy them from `/tmp/xwiki/.ssh` to `/root/.ssh` and set the correct permissions. The `ro` is just safety to make sure the container can never modify your keys.
  * The `-v $HOME/.gnupg:/root/.gnupg` is to have your GPG key inside the container. This is needed when doing a Maven release for example.
  * The ``` -v `pwd`:/root/`basename \`pwd\``:delegated ``` is to avoid having to clone the Maven module to build and/or to build with local changes
  * The `-e DISPLAY=$IP:0` is to forward the display to your Mac.
  * The `-p 8080:8080` is to be able to access any XWiki instance running in the container from a local browser with
  `http://localhost:8080`
  * The `--privileged` is because... not sure why but it might be required for some cases ;)

## On Linux

Same as on Mac but someone will need to figure out and test how to have the UI displayed locally on the machine :)

```bash
docker run -d --rm \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v $HOME/.m2:/root/.m2:delegated \
  -v $HOME/.git-credentials:/root/.git-credentials \
  -v $HOME/.git-gitconfig:/root/.git-gitconfig \
  -v $HOME/.gitconfig:/root/.gitconfig \
  -v $HOME/.gitignore_global:/root/.gitignore_global \
  -v $HOME/.ssh:/tmp/xwiki/.ssh:ro \
  -v $HOME/.gnupg:/root/.gnupg \
  -v `pwd`:/root/`basename \`pwd\``:delegated \
  -p 8080:8080 --privileged xwiki/build
```
