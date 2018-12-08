Custom Docker image for the XWiki project, used to spawn Jenkins Slave agents for https://ci.xwiki.org.

This image adds the following XWiki-required build tools over the `jenkins/ssh-slave` base image provided by Jenkins:
* `vncserver`

This image is built automatically by Dockerhub.
