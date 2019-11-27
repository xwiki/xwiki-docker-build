
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
FROM xwiki/build

#    ____  ____  ____      ____  _   __        _
#   |_  _||_  _||_  _|    |_  _|(_) [  |  _   (_)
#     \ \  / /    \ \  /\  / /  __   | | / ]  __
#      > `' <      \ \/  \/ /  [  |  | '' <  [  |
#    _/ /'`\ \_     \  /\  /    | |  | |`\ \  | |
#   |____||____|     \/  \/    [___][__|  \_][___]

MAINTAINER XWiki Development Teeam <committers@xwiki.org>

# Specify the version of XWiki to use for running android tests
ENV XWIKI_LTS 10.11.10
ENV XWIKI_LTS_NAME xwiki-platform-distribution-flavor-jetty-hsqldb-$XWIKI_LTS
ENV XWIKI_LTS_ZIP_URL https://maven.xwiki.org/releases/org/xwiki/platform/xwiki-platform-distribution-flavor-jetty-hsqldb/$XWIKI_LTS/$XWIKI_LTS_NAME.zip
ENV XWIKI_LTS_HOME /opt/xwiki-lts

# Inspired by setup from https://github.com/WindSekirun/Jenkins-Android-Docker
ENV ANDROID_SDK_ZIP sdk-tools-linux-4333796.zip
ENV ANDROID_SDK_ZIP_URL https://dl.google.com/android/repository/$ANDROID_SDK_ZIP
ENV ANDROID_HOME /opt/android-sdk-linux

ENV PATH $PATH:$ANDROID_HOME/tools/bin
ENV PATH $PATH:$ANDROID_HOME/platform-tools
ENV PATH $PATH:$XWIKI_LTS_HOME

RUN apt install -y --no-install-recommends unzip
ADD $ANDROID_SDK_ZIP_URL /opt/
RUN unzip -q /opt/$ANDROID_SDK_ZIP -d $ANDROID_HOME && rm /opt/$ANDROID_SDK_ZIP

RUN echo y | sdkmanager platform-tools "build-tools;29.0.2"
RUN echo y | sdkmanager platform-tools "platforms;android-29"
RUN echo y | sdkmanager platform-tools "build-tools;28.0.3"
RUN echo y | sdkmanager platform-tools "platforms;android-28"
RUN echo y | sdkmanager emulator
RUN echo y | sdkmanager "system-images;android-19;google_apis;armeabi-v7a"

ADD $XWIKI_LTS_ZIP_URL /opt/
RUN unzip -q /opt/$XWIKI_LTS_NAME.zip -d /opt && rm /opt/$XWIKI_LTS_NAME.zip
RUN mv /opt/$XWIKI_LTS_NAME $XWIKI_LTS_HOME && chmod +x $XWIKI_LTS_HOME/*.sh

RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*