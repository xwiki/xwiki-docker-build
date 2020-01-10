Description
===========

Custom Docker images for the XWiki project, used to spawn Jenkins Agents for https://ci.xwiki.org.

Two images are available:
  * [`xwiki/build`](./build) Minimum configuration to build XWiki Platform.
  * [`xwiki/build-android`](./build-android) Based on the previous one, also contains an Android SDK to build XWiki Android applications.
  * [`xwiki/build-oracle`](./build-oracle) Custom Oracle Database 19.3.0 Standard Edition image to test XWiki on Oracle.