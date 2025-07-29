# ---------------------------------------------------------------------------
# See the NOTICE file distributed with this work for additional
# information regarding copyright ownership.
#
# This is free software; you can redistribute it and/or modify it
# under the terms of the GNU Lesser General Public License as
# published by the Free Software Foundation; either version 2.1 of
# the License, or (at your option) any later version.
#
# This software is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this software; if not, write to the Free
# Software Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
# 02110-1301 USA, or see the FSF site: http://www.fsf.org.
# ---------------------------------------------------------------------------
FROM jenkins/ssh-agent:jdk21

#    ____  ____  ____      ____  _   __        _
#   |_  _||_  _||_  _|    |_  _|(_) [  |  _   (_)
#     \ \  / /    \ \  /\  / /  __   | | / ]  __
#      > `' <      \ \/  \/ /  [  |  | '' <  [  |
#    _/ /'`\ \_     \  /\  /    | |  | |`\ \  | |
#   |____||____|     \/  \/    [___][__|  \_][___]

LABEL maintainer="XWiki Development Team <committers@xwiki.org>"

# Install:
# - VNC
# - Docker CE
# - lsof, to list open ports for debugging reasons
# - netstats (through net-tools), for debugging reasons
# - bc needed by some building scripts (e.g. CKEditor)
# - wget needed by this Dockerfile to download Firefox
# - other tools needed by the Dockerfile (such as zip, etc)
RUN apt-get update && \
  apt-get --no-install-recommends -y install \
    apt-transport-https \
    ca-certificates \
    curl \
    wget \
    gnupg2 \
    zip \
    bzip2 \
    lsof \
    software-properties-common \
    net-tools \
    bc
RUN install -m 0755 -d /etc/apt/keyrings && \
      curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc && \
      chmod a+r /etc/apt/keyrings/docker.asc
RUN echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null
# Note: We must install the same version of Docker that is installed on the CI agents since we share the same docker
# socket (docker on docker) and we want to reduce likelihood of issues.
RUN apt-get update && \
  apt-get --no-install-recommends -y install \
    xfce4 xfce4-goodies xfonts-base tightvncserver docker-ce=5:24.0.7-1~debian.12~bookworm

# Install Firefox.
# Note 1: This won't be needed when we'll have all our functional tests use docker. However, as a transitional step,
# we should provide it, so that all agents can use this image to build XWiki fully.
# Note 2: The FF version we install is the version of the selenium/standalone-firefox-debug image used by TestContainers
# See https://dev.xwiki.org/xwiki/bin/view/Community/Testing/DockerTesting/#HFirefoxVersionUsed
# Note 3: We also install FF 32.0.1 for older branches still using Selenium 2.x
ENV FIREFOX_VERSION_1 latest
ENV FIREFOX_DOWNLOAD_URL_1="https://download.mozilla.org/?product=firefox-latest-ssl&os=linux64"
ENV FIREFOX_VERSION_2 32.0.1
ENV FIREFOX_DOWNLOAD_URL_2="https://ftp.mozilla.org/pub/firefox/releases/$FIREFOX_VERSION_2/linux-x86_64/en-US/firefox-$FIREFOX_VERSION_2.tar.bz2"
RUN apt-get --no-install-recommends -y install libasound2 libdbus-glib-1-2 libgtk2.0-0 xz-utils && \
  wget --no-verbose -O /tmp/firefox1.tar.xz $FIREFOX_DOWNLOAD_URL_1 && \
  rm -rf /opt/firefox && \
  tar -C /opt -xf /tmp/firefox1.tar.xz && \
  rm /tmp/firefox1.tar.xz && \
  mv /opt/firefox /opt/firefox-$FIREFOX_VERSION_1 && \
  ln -fs /opt/firefox-$FIREFOX_VERSION_1/firefox /usr/bin/firefox && \
  wget --no-verbose -O /tmp/firefox2.tar.bz2 $FIREFOX_DOWNLOAD_URL_2 && \
  tar -C /opt -xjf /tmp/firefox2.tar.bz2 && \
  rm /tmp/firefox2.tar.bz2 && \
  mv /opt/firefox /opt/firefox-$FIREFOX_VERSION_2 && \
  ln -fs /opt/firefox-$FIREFOX_VERSION_2 /usr/bin/firefox-$FIREFOX_VERSION_2

WORKDIR /root

# Setup Adoptium repository
RUN apt install -y wget apt-transport-https gnupg
RUN wget -O - https://packages.adoptium.net/artifactory/api/gpg/key/public | apt-key add -
RUN echo "deb https://packages.adoptium.net/artifactory/deb $(awk -F= '/^VERSION_CODENAME/{print$2}' /etc/os-release) main" | tee /etc/apt/sources.list.d/adoptium.list
RUN apt update

# Install Java 8, 11 and 17
RUN apt install -y temurin-8-jdk temurin-11-jdk temurin-17-jdk

# Copy VNC config files
COPY vnc/.Xauthority .Xauthority
COPY vnc/.vnc .vnc

# Generate a password for XVNC
RUN echo "jenkins" | vncpasswd -f > .vnc/passwd

# This is important as otherwise vncserver requires a password when started
RUN chmod 0600 .vnc/passwd

# Install the latest Maven version supported by the XWiki build, so that developers can benefit from the Gradle
# Enterprise remote cache (https://ge.xwiki.org), as it'll only be triggered if the Maven version is the same on the
# CI and locally (note: bugfix versions are not taken into account).
ENV MAVEN_VERSION 3.9.11
# TODO: Remove --no-check-certificat when the certificate for archive.apache.org is good again (it's currently expired)
RUN wget --no-check-certificate https://archive.apache.org/dist/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz && \
  tar -xvzf apache-maven-$MAVEN_VERSION-bin.tar.gz && \
  rm apache-maven-$MAVEN_VERSION-bin.tar.gz

# ci.xwiki.org expects:
# - Java17 to be available at /home/hudsonagent/java17
# - Java11 to be available at /home/hudsonagent/java11
# - Java8 to be available at /home/hudsonagent/java8
# - Java17 to be available at /home/hudsonagent/java
# - Maven to be available at /home/hudsonagent/maven
# - "mvn" to be on the path
RUN mkdir -p /home/hudsonagent && \
  ln -fs /usr/lib/jvm/temurin-17-jdk-amd64 /home/hudsonagent/java17 && \
  ln -fs /usr/lib/jvm/temurin-11-jdk-amd64/ /home/hudsonagent/java11 && \
  ln -fs /usr/lib/jvm/temurin-8-jdk-amd64/ /home/hudsonagent/java8 && \
  ln -fs /home/hudsonagent/java17 /home/hudsonagent/java && \
  ln -fs /root/apache-maven-$MAVEN_VERSION /home/hudsonagent/maven && \
  # Use /etc/profile.d so that Maven is in all paths for all shells (sh, bash, etc), when using login, for example
  # with "docker exec -it ... bash -l".
  echo 'export M2_HOME=/home/hudsonagent/maven' > /etc/profile.d/xwiki.sh && \
  echo 'export PATH=$M2_HOME/bin:/usr/bin:$PATH' >> /etc/profile.d/xwiki.sh
  # Override the /usr/local/openjdk-11/bin path set by the parent image, to use our java version by default
  #echo 'export PATH=/usr/bin/java:$PATH' >> /root/.profile
# Needed so that invocation through "docker run ... --entrypoint "/bin/sh" or "/bin/bash" work fine (i.e without login)
ENV PATH="/home/hudsonagent/maven/bin:/usr/bin:${PATH}"

# Set up the default Maven repository configuration (settings.xml)
RUN mkdir -p /root/.m2
COPY maven/settings.xml /root/.m2/settings.xml

# Set locales
RUN apt-get --no-install-recommends -y install locales && \
  rm -rf /var/lib/apt/lists/* /var/cache/apt/*
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
  locale-gen
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

ENV USER root
ENV JAVA_HOME /home/hudsonagent/java
# Environment variable needed to have phantomJS working in our Jasmine tests.
ENV OPENSSL_CONF "/etc/ssl"
COPY ssh/setup-xwiki-ssh /usr/local/bin/setup-xwiki-ssh
RUN chmod a+x /usr/local/bin/setup-xwiki-ssh

ENTRYPOINT ["setup-xwiki-ssh"]
