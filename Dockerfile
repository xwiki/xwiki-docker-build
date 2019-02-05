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
FROM jenkins/ssh-slave

#    ____  ____  ____      ____  _   __        _
#   |_  _||_  _||_  _|    |_  _|(_) [  |  _   (_)
#     \ \  / /    \ \  /\  / /  __   | | / ]  __
#      > `' <      \ \/  \/ /  [  |  | '' <  [  |
#    _/ /'`\ \_     \  /\  /    | |  | |`\ \  | |
#   |____||____|     \/  \/    [___][__|  \_][___]

MAINTAINER XWiki Development Teeam <committers@xwiki.org>

# Install VNC + Docker CE
RUN apt-get update && \
  apt-get --no-install-recommends -y install \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg2 \
    zip \
    software-properties-common
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
RUN add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"
RUN apt-get update && \
  apt-get --no-install-recommends -y install \
    xfce4 xfce4-goodies xfonts-base tightvncserver docker-ce && \
  rm -rf /var/lib/apt/lists/*

WORKDIR /root

# Install a recent version of Java. We need >= 8u191-b12. See https://dev.xwiki.org/xwiki/bin/view/Community/Building/
# Since jenkins/ssh-slave depends on Debian Stretch, which has only 8u181 as the latest version we need to remove it
# and use another mechanism to install a recent Java. We use Sdkman.
RUN apt purge openjdk-8-jdk -y && \
  apt autoremove -y && \
  curl -s "https://get.sdkman.io" | bash && \
  /bin/bash -l -c 'source "/root/.sdkman/bin/sdkman-init.sh"' && \
  /bin/bash -l -c 'sdk install java 8.0.202-amzn'

# ci.xwiki.org expects java to be available at /home/hudsonagent/java8
RUN mkdir -p /home/hudsonagent
RUN ln -fs /root/.sdkman/candidates/java/current/bin/java /home/hudsonagent/java8
RUN ln -fs /home/hudsonagent/java8 /home/hudsonagent/java
ENV JAVA_HOME /home/hudsonagent/java

# Copy VNC config files
COPY vnc/.Xauthority .Xauthority
COPY vnc/.vnc .vnc

# Generate a password for XVNC
RUN echo "jenkins" | vncpasswd -f > .vnc/passwd

# This is important as otherwise vncserver requires a password when started
RUN chmod 0600 .vnc/passwd

# Set up the Maven repository configuration (settings.xml)
RUN mkdir -p /root/.m2
COPY maven/settings.xml /root/.m2/settings.xml

ENV USER root
