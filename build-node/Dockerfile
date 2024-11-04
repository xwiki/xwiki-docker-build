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
# Initialize an agent with node tooling installed (i.e., node, npm, and pnpm)
# We use a multi stages build to install pnpm in a node container, before copying the node executables the Jenkins
# agent without persisting intermediate layers, for a lighter docker image.
FROM node:22.11.0 AS node_base
# Enable corepack to be able to manipulate pnpm version.
RUN corepack enable
# Activate and install pnpm.
RUN corepack prepare pnpm@9.12.2 --activate
# The final docker image of the multi stage build.
FROM jenkins/ssh-agent:jdk11
# Copy of the location of the installed node tools.
COPY --from=node_base /usr/local/lib/node_modules/ /usr/local/lib/node_modules/
# Copy of the symbolic links to the installed node tools in a folder of the PATH.
COPY --from=node_base /usr/local/bin/ /usr/local/bin/
## Install playwright dependencies
RUN pnpx playwright@1.47.2 install && pnpx playwright@1.47.2 install-deps
