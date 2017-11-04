# PHP-FPM 7.3 Docker Image

[![Build Status](https://travis-ci.org/devilbox/docker-php-fpm-7.3.svg?branch=master)](https://travis-ci.org/devilbox/docker-php-fpm-7.3)
[![Join the chat at https://gitter.im/devilbox/Lobby](https://badges.gitter.im/devilbox/Lobby.svg)](https://gitter.im/devilbox/Lobby?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)
[![](https://images.microbadger.com/badges/license/devilbox/php-fpm-7.3.svg)](https://microbadger.com/images/devilbox/php-fpm-7.3 "php-fpm-7.3")
[![Github](https://img.shields.io/badge/github-docker--php--fpm--7.3-red.svg)](https://github.com/devilbox/docker-php-fpm-7.3)

**[devilbox/docker-php-fpm-7.3](https://github.com/devilbox/docker-php-fpm-7.3)**

This repository will provide you fully functional PHP-FPM 7.3 Docker images in different flavours and packed with different types of integrated PHP modules. It also solves the problem of [syncronizing file permissions](#unsynchronized-permissions) of mounted volumes between the host and the container.

Choose between [Alpine](https://www.alpinelinux.org) or [Debian](https://www.debian.org) and select an image type for extending, use in production or use for local development. Images are always guaranteed to be fresh and up-to-date as they are automatically built every night by [travis-ci](https://travis-ci.org/devilbox/docker-php-fpm-7.3) and pushed to [Docker hub](https://hub.docker.com/r/devilbox/php-fpm-7.3/).


| Docker Hub | Upstream Project |
|------------|------------------|
| <a href="https://hub.docker.com/r/devilbox/php-fpm-7.3"><img height="82px" src="http://dockeri.co/image/devilbox/php-fpm-7.3" /></a> | <a href="https://github.com/cytopia/devilbox" ><img height="82px" src="https://raw.githubusercontent.com/devilbox/artwork/master/submissions_banner/cytopia/01/png/banner_256_trans.png" /></a> |

**Select different version**

**[PHP 5.4](https://github.com/cytopia/docker-php-fpm-5.4)** |
**[PHP 5.5](https://github.com/cytopia/docker-php-fpm-5.5)** |
**[PHP 5.6](https://github.com/cytopia/docker-php-fpm-5.6)** |
**[PHP 7.0](https://github.com/cytopia/docker-php-fpm-7.0)** |
**[PHP 7.1](https://github.com/cytopia/docker-php-fpm-7.1)** |
**[PHP 7.2](https://github.com/cytopia/docker-php-fpm-7.2)** |
**PHP 7.3** |
**[HHVM latest](https://github.com/cytopia/docker-hhvm-latest)**

---

#### Table of Contents

1. **[Motivation](#motivation)**
    1. [Unsynchronized permissions](#unsynchronized-permissions)
    2. [It gets even worse](#it-gets-even-worse)
    3. [The solution](#the-solution)
2. **[PHP-FPM 7.3 Flavours](#php-fpm-7.3-flavours)**
    1. [Assembly](#assembly)
    2. [Available Images](#available-images)
    3. [Tagging](#tagging)
    4. [PHP Modules](#php-modules)
3. **[PHP-FPM 7.3 Features](#php-fpm-7.3-features)**
    1. [Image: base](#image-base)
    2. [Image: mods](#image-mods)
    3. [Image: prod](#image-prod)
    4. [Image: work](#image-work)
4. **[PHP-FPM 7.3 Options](#php-fpm-7.3-options)**
    1. [Environment variables](#environment-variables)
    2. [Volumes](#volumes)
    3. [Ports](#ports)
5. **[Integrated Development Environment](#integrated-development-environment)**
    1. [What toos can you expect](#what-tools-can-you-expect)
    2. [What else is available](#what-else-is-available)
6. **[Examples](#examples)**
    1. [Provide PHP-FPM port to host](#provide-php-fpm-port-to-host)
    2. [Alter PHP-FPM and system timezone](#alter-php-fpm-and-system-timezone)
    3. [Load custom PHP configuration](#load-custom-php-configuration)
    4. [Load custom PHP modules](#load-custom-php-modules)
    5. [MySQL connect via 127.0.0.1 (via port-forward)](#mysql-connect-via-127-0-0-1-via-port-forward-)
    6. [MySQL and Redis connect via 127.0.0.1 (via port-forward)](#mysql-and-redis-connect-via-127-0-0-1-via-port-forward-)
    7. [Launch Postfix for mail-catching](#launch-postfix-for-mail-catching)
    8. [Webserver and PHP-FPM](#webserver-and-php-fpm)
7. **[Automated builds](#automated-builds)**
8. **[Contributing](#contributing)**
9. **[Credits](#credits)**
10. **[License](#license)**

----

<h2><img id="motivation" width="20" src="https://github.com/devilbox/artwork/raw/master/submissions_logo/cytopia/01/png/logo_64_trans.png"> Motivation</h2>

One main problem with a running Docker container is to **synchronize the ownership of files in a mounted volume** in order to preserve security (Not having to use `chmod 0777`).


#### Unsynchronized permissions

Consider the following directory structure of a mounted volume. Your hosts computer uid/gid are `1000` which does not have a corresponding user/group within the container. Fortunately the `tmp/` directory allows everybody to create new files in it. 

```shell
                  [Host]                   |             [Container]
------------------------------------------------------------------------------------------
 $ ls -l                                   | $ ls -l
 -rw-r--r-- user group index.php           | -rw-r--r-- 1000 1000 index.php
 drwxrwxrwx user group tmp/                | drwxrwxrwx 1000 1000 tmp/
```

Your web application might now have created some temporary files (via the PHP-FPM process) inside the `tmp/` directory:

```shell
                  [Host]                   |             [Container]
------------------------------------------------------------------------------------------
 $ ls -l tmp/                              | $ ls -l tmp/
 -rw-r--r-- 96 96 _tmp_cache01.php         | -rw-r--r-- www www _tmp_cache01.php
 -rw-r--r-- 96 96 _tmp_cache02.php         | -rw-r--r-- www www _tmp_cache01.php
```

On the Docker container side everything is still fine, but on your host computers side, those files now show a user id and group id of `96`, which is in fact the uid/gid of the PHP-FPM process running inside the container. On the host side you will now have to use `sudo` in order to delete/edit those files.

#### It gets even worse

Consider your had created the `tmp/` directory on your host only with `0775` permissions:

```shell
                  [Host]                   |             [Container]
------------------------------------------------------------------------------------------
 $ ls -l                                   | $ ls -l
 -rw-r--r-- user group index.php           | -rw-r--r-- 1000 1000 index.php
 drwxrwxr-x user group tmp/                | drwxrwxr-x 1000 1000 tmp/
```

If your web application now wants to create some temporary files (via the PHP-FPM process) inside the `tmp/` directory, it will fail due to lacking permissions.

#### The solution

To overcome this problem, it must be made sure that the PHP-FPM process inside the container runs under the same uid/gid as your local user that mouns the volumes and also wants to work on those files locally. However, you never know during Image build time what user id this would be. Therefore it must be something that can be changed during startup of the container.

This is achieved by two environment variables that can be provided during startup in order to change the uid/gid of the PHP-FPM user prior starting up PHP-FPM.

```shell
$ docker run -e NEW_UID=1000 -e NEW_GID=1000 -it devilbox/php-fpm-7.3:base-alpine
[INFO] Changing user 'devilbox' uid to: 1000
root $ usermod -u 1000 devilbox
[INFO] Changing group 'devilbox' gid to: 1000
root $ groupmod -g 1000 devilbox
[INFO] Starting PHP 7.3.0-dev (fpm-fcgi) (built: Oct 30 2017 12:05:19)
```

When **`NEW_UID`** and **`NEW_GID`** are provided to the startup command, the container will do a `usermod` and `groupmod` prior starting up in order to assign new uid/gid to the PHP-FPM user. When the PHP-FPM process finally starts up it actually runs with your local system user and making sure permissions will be in sync from now on.

At a minimum those two environment variables are offered by all flavours and types of the here provided PHP-FPM images.

**Note:**

To tackle this on the PHP-FPM side is only half a solution to the problem. The same applies to a web server Docker container when you offer **file uploads**. They will be uploaded and created by the web servers uid/gid. Therefore the web server itself must also provide the same kind of solution. See the following Web server Docker images for how this is done:

**[Apache 2.2](https://github.com/devilbox/docker-apache-2.2)** |
**[Apache 2.4](https://github.com/devilbox/docker-apache-2.4)** |
**[Nginx stable](https://github.com/devilbox/docker-nginx-stable)** |
**[Nginx mainline](https://github.com/devilbox/docker-nginx-mainline)**


<h2><img id="php-fpm-7.3-flavours" width="20" src="https://github.com/devilbox/artwork/raw/master/submissions_logo/cytopia/01/png/logo_64_trans.png"> PHP-FPM 7.3 Flavours</h2>

#### Assembly

The provided Docker images heavily rely on inheritance to guarantee smallest possible image size. Each of them provide a working PHP-FPM server and you must decide what version works best for you. Look at the sketch below to get an overview about the two provided flavours and each of their different types.

```shell
      [Alpine]               [Debian]          # Base FROM image
         ^                      ^              #
         |                      |              #
         |                      |              #
    [base-alpine]          [base-debian]       # Clones PHP git repository, compiles
         ^                      ^              # and installs it
         |                      |              #
         |                      |              #
    [mods-alpine]          [mods-debian]       # Installs additional PHP modules
         ^                      ^              # via pecl
         |                      |              #
         |                      |              #
    [prod-alpine]          [prod-debian]       # Devilbox flavour for production
         ^                      ^              # (locales, postifx, socat and injectables)
         |                      |              # (custom modules and *.ini files)
         |                      |              #
    [work-alpine]          [work-debian]       # Devilbox flavour for local development
                                               # (includes backup and development tools)
                                               # (sudo, custom bash and tool configs)
```

#### Available Images

The following table shows a more complete overview about the offered Docker images and what they should be used for.

<table>
 <thead>
  <tr>
   <th width="80">Type</th>
   <th width="310">Docker Image</th>
   <th>Description</th>
  </tr>
 </thead>
 <tbody>
  <tr>
   <td rowspan="2"><strong>base</strong></td>
   <td><code>devilbox/php-fpm-7.3:base-alpine</code></td>
   <td><img src="https://images.microbadger.com/badges/image/devilbox/php-fpm-7.3:base-alpine.svg" /> <img src="https://images.microbadger.com/badges/version/devilbox/php-fpm-7.3:base-alpine.svg" /></td>
  </tr>
  <tr>
   <td><code>devilbox/php-fpm-7.3:base-debian</code></td>
   <td><img src="https://images.microbadger.com/badges/image/devilbox/php-fpm-7.3:base-debian.svg" /> <img src="https://images.microbadger.com/badges/version/devilbox/php-fpm-7.3:base-debian.svg" /></td>
  </tr>
  <tr>
   <td colspan="3"></td>
  </tr>
  <tr>
   <td rowspan="2"><strong>mods</strong></td>
   <td><code>devilbox/php-fpm-7.3:mods-alpine</code></td>
   <td><img src="https://images.microbadger.com/badges/image/devilbox/php-fpm-7.3:mods-alpine.svg" /> <img src="https://images.microbadger.com/badges/version/devilbox/php-fpm-7.3:mods-alpine.svg" /></td>
  </tr>
  <tr>
   <td><code>devilbox/php-fpm-7.3:mods-debian</code></td>
   <td><img src="https://images.microbadger.com/badges/image/devilbox/php-fpm-7.3:mods-debian.svg" /> <img src="https://images.microbadger.com/badges/version/devilbox/php-fpm-7.3:mods-debian.svg" /></td>
  </tr>
  <tr>
   <td colspan="3"></td>
  </tr>
  <tr>
   <td rowspan="2"><strong>prod</strong></td>
   <td><code>devilbox/php-fpm-7.3:prod-alpine</code></td>
   <td><img src="https://images.microbadger.com/badges/image/devilbox/php-fpm-7.3:prod-alpine.svg" /> <img src="https://images.microbadger.com/badges/version/devilbox/php-fpm-7.3:prod-alpine.svg" /></td>
  </tr>
  <tr>
   <td><code>devilbox/php-fpm-7.3:prod-debian</code></td>
   <td><img src="https://images.microbadger.com/badges/image/devilbox/php-fpm-7.3:prod-debian.svg" /> <img src="https://images.microbadger.com/badges/version/devilbox/php-fpm-7.3:prod-debian.svg" /></td>
  </tr>
  <tr>
   <td colspan="3"></td>
  </tr>
  <tr>
   <td rowspan="2"><strong>work</strong></td>
   <td><code>devilbox/php-fpm-7.3:work-alpine</code></td>
   <td><img src="https://images.microbadger.com/badges/image/devilbox/php-fpm-7.3:work-alpine.svg" /> <img src="https://images.microbadger.com/badges/version/devilbox/php-fpm-7.3:work-alpine.svg" /></td>
  </tr>
  <tr>
   <td><code>devilbox/php-fpm-7.3:work-debian</code></td>
   <td><img src="https://images.microbadger.com/badges/image/devilbox/php-fpm-7.3:work-debian.svg" /> <img src="https://images.microbadger.com/badges/version/devilbox/php-fpm-7.3:work-debian.svg" /></td>
  </tr>
 </tbody>
</table>

#### Tagging

This repository uses Docker tags to refer to different flavours and types of the PHP-FPM 7.3 Docker image. Therefore `:latest` and `:<git-branch-name>` as well as `:<git-tag-name>` must be presented differently. Refer to the following table to see how tagged Docker images are produced at Docker hub:

<table>
 <thead>
  <tr>
   <th width="190">Meant Tag</th>
   <th width="300">Actual Tag</th>
   <th>Comment</th>
  </tr>
 </thead>
 <tbody>
  <tr>
   <td><code>:latest</code></td>
   <td>
    <code>:base-alpine</code><br/>
    <code>:base-debian</code><br/>
    <code>:mods-alpine</code><br/>
    <code>:mods-debian</code><br/>
    <code>:prod-alpine</code><br/>
    <code>:prod-debian</code><br/>
    <code>:work-alpine</code><br/>
    <code>:work-debian</code>
   </td>
   <td>Stable<br/><sub>(rolling)</sub><br/><br/>These tags are produced by the master branch of this repository.</td>
  </tr>
  <tr>
   <td><code>:&lt;git-tag-name&gt;</code></td>
   <td>
    <code>:base-alpine-&lt;git-tag-name&gt;</code><br/>
    <code>:base-debian-&lt;git-tag-name&gt;</code><br/>
    <code>:mods-alpine-&lt;git-tag-name&gt;</code><br/>
    <code>:mods-debian-&lt;git-tag-name&gt;</code><br/>
    <code>:prod-alpine-&lt;git-tag-name&gt;</code><br/>
    <code>:prod-debian-&lt;git-tag-name&gt;</code><br/>
    <code>:work-alpine-&lt;git-tag-name&gt;</code><br/>
    <code>:work-debian-&lt;git-tag-name&gt;</code>
   </td>
   <td>Stable<br/><sub>(fixed)</sub><br/><br/>Every git tag will produce and preserve these Docker tags.</td>
  </tr>
  <tr>
   <td><code>:&lt;git-branch-name&gt;</code></td>
   <td>
    <code>:base-alpine-&lt;git-branch-name&gt;</code><br/>
    <code>:base-debian-&lt;git-branch-name&gt;</code><br/>
    <code>:mods-alpine-&lt;git-branch-name&gt;</code><br/>
    <code>:mods-debian-&lt;git-branch-name&gt;</code><br/>
    <code>:prod-alpine-&lt;git-branch-name&gt;</code><br/>
    <code>:prod-debian-&lt;git-branch-name&gt;</code><br/>
    <code>:work-alpine-&lt;git-branch-name&gt;</code><br/>
    <code>:work-debian-&lt;git-branch-name&gt;</code>
   </td>
   <td>Feature<br/><sub>(for testing)</sub><br/><br/>Tags produced by unmerged branches. Do not rely on them as they might come and go.</td>
  </tr>
 </tbody>
</table>


#### PHP Modules

Check out this table to see which Docker image provides what PHP modules.

<table>
 <thead>
  <tr>
   <th></th>
   <th width="45%">Alpine</th>
   <th width="45%">Debian</th>
  </tr>
 </thead>
 <tbody>
  <tr>
   <th>base</th>
   <td id="mod-base-alpine">bcmath, bz2, calendar, Core, ctype, curl, date, dom, enchant, exif, fileinfo, filter, ftp, gd, gettext, gmp, hash, iconv, imap, intl, json, ldap, libxml, mbstring, mysqli, mysqlnd, openssl, pcntl, pcre, PDO, pdo_mysql, pdo_pgsql, pdo_sqlite, pgsql, Phar, posix, pspell, readline, Reflection, session, shmop, SimpleXML, snmp, soap, sockets, SPL, sqlite3, standard, sysvmsg, sysvsem, sysvshm, tidy, tokenizer, wddx, xml, xmlreader, xmlrpc, xmlwriter, xsl, zip, zlib</td>
   <td id="mod-base-debian">bcmath, bz2, calendar, Core, ctype, curl, date, dom, enchant, exif, fileinfo, filter, ftp, gd, gettext, gmp, hash, iconv, imap, interbase, intl, json, ldap, libxml, mbstring, mysqli, mysqlnd, openssl, pcntl, pcre, PDO, PDO_Firebird, pdo_mysql, pdo_pgsql, pdo_sqlite, pgsql, Phar, posix, pspell, readline, Reflection, session, shmop, SimpleXML, snmp, soap, sockets, SPL, sqlite3, standard, sysvmsg, sysvsem, sysvshm, tidy, tokenizer, wddx, xml, xmlreader, xmlrpc, xmlwriter, xsl, zip, zlib</td>
  </tr>
  <tr>
   <th>mods</th>
   <td id="mod-mods-alpine">bcmath, bz2, calendar, Core, ctype, curl, date, dom, enchant, exif, fileinfo, filter, ftp, gd, gettext, gmp, hash, iconv, igbinary, imap, intl, json, ldap, libxml, mbstring, mysqli, mysqlnd, openssl, pcntl, pcre, PDO, pdo_mysql, pdo_pgsql, pdo_sqlite, pgsql, Phar, posix, pspell, readline, redis, Reflection, session, shmop, SimpleXML, snmp, soap, sockets, SPL, sqlite3, standard, sysvmsg, sysvsem, sysvshm, tidy, tokenizer, wddx, xml, xmlreader, xmlrpc, xmlwriter, xsl, zip, zlib</td>
   <td id="mod-mods-debian">bcmath, bz2, calendar, Core, ctype, curl, date, dom, enchant, exif, fileinfo, filter, ftp, gd, gettext, gmp, hash, iconv, igbinary, imagick, imap, interbase, intl, json, ldap, libxml, mbstring, mongodb, msgpack, mysqli, mysqlnd, openssl, pcntl, pcre, PDO, PDO_Firebird, pdo_mysql, pdo_pgsql, pdo_sqlite, pgsql, Phar, posix, pspell, readline, redis, Reflection, session, shmop, SimpleXML, snmp, soap, sockets, SPL, sqlite3, standard, sysvmsg, sysvsem, sysvshm, tidy, tokenizer, wddx, xml, xmlreader, xmlrpc, xmlwriter, xsl, zip, zlib</td>
  </tr>
  <tr>
   <th>prod</th>
   <td id="mod-prod-alpine">bcmath, bz2, calendar, Core, ctype, curl, date, dom, enchant, exif, fileinfo, filter, ftp, gd, gettext, gmp, hash, iconv, igbinary, imap, intl, json, ldap, libxml, mbstring, mysqli, mysqlnd, openssl, pcntl, pcre, PDO, pdo_mysql, pdo_pgsql, pdo_sqlite, pgsql, Phar, posix, pspell, readline, redis, Reflection, session, shmop, SimpleXML, snmp, soap, sockets, SPL, sqlite3, standard, sysvmsg, sysvsem, sysvshm, tidy, tokenizer, wddx, xml, xmlreader, xmlrpc, xmlwriter, xsl, zip, zlib</td>
   <td id="mod-prod-debian">bcmath, bz2, calendar, Core, ctype, curl, date, dom, enchant, exif, fileinfo, filter, ftp, gd, gettext, gmp, hash, iconv, igbinary, imagick, imap, interbase, intl, json, ldap, libxml, mbstring, mongodb, msgpack, mysqli, mysqlnd, openssl, pcntl, pcre, PDO, PDO_Firebird, pdo_mysql, pdo_pgsql, pdo_sqlite, pgsql, Phar, posix, pspell, readline, redis, Reflection, session, shmop, SimpleXML, snmp, soap, sockets, SPL, sqlite3, standard, sysvmsg, sysvsem, sysvshm, tidy, tokenizer, wddx, xml, xmlreader, xmlrpc, xmlwriter, xsl, zip, zlib</td>
  </tr>
  <tr>
   <th>work</th>
   <td id="mod-work-alpine">bcmath, bz2, calendar, Core, ctype, curl, date, dom, enchant, exif, fileinfo, filter, ftp, gd, gettext, gmp, hash, iconv, igbinary, imap, intl, json, ldap, libxml, mbstring, mysqli, mysqlnd, openssl, pcntl, pcre, PDO, pdo_mysql, pdo_pgsql, pdo_sqlite, pgsql, Phar, posix, pspell, readline, redis, Reflection, session, shmop, SimpleXML, snmp, soap, sockets, SPL, sqlite3, standard, sysvmsg, sysvsem, sysvshm, tidy, tokenizer, wddx, xml, xmlreader, xmlrpc, xmlwriter, xsl, zip, zlib</td>
   <td id="mod-work-debian">bcmath, bz2, calendar, Core, ctype, curl, date, dom, enchant, exif, fileinfo, filter, ftp, gd, gettext, gmp, hash, iconv, igbinary, imagick, imap, interbase, intl, json, ldap, libxml, mbstring, mongodb, msgpack, mysqli, mysqlnd, openssl, pcntl, pcre, PDO, PDO_Firebird, pdo_mysql, pdo_pgsql, pdo_sqlite, pgsql, Phar, posix, pspell, readline, redis, Reflection, session, shmop, SimpleXML, snmp, soap, sockets, SPL, sqlite3, standard, sysvmsg, sysvsem, sysvshm, tidy, tokenizer, wddx, xml, xmlreader, xmlrpc, xmlwriter, xsl, zip, zlib</td>
  </tr>
 </tbody>
</table>


<h2><img id="php-fpm-7.3-features" width="20" src="https://github.com/devilbox/artwork/raw/master/submissions_logo/cytopia/01/png/logo_64_trans.png"> PHP-FPM 7.3 Features</h2>

#### Image: base
<img src="https://images.microbadger.com/badges/version/devilbox/php-fpm-7.3:base-alpine.svg" /> <img src="https://images.microbadger.com/badges/image/devilbox/php-fpm-7.3:base-alpine.svg" /><br/>
<img src="https://images.microbadger.com/badges/version/devilbox/php-fpm-7.3:base-debian.svg" /> <img src="https://images.microbadger.com/badges/image/devilbox/php-fpm-7.3:base-debian.svg" /> 
```shell
docker pull devilbox/php-fpm-7.3:base-alpine
docker pull devilbox/php-fpm-7.3:base-debian
```

Generic PHP-FPM base image. Use it to derive your own php-fpm docker image from it and add more extensions, tools and injectables.<br/><br/><sub>(Does not offer any environment variables except for `NEW_UID` and `NEW_GID`)</sub>

#### Image: mods
<img src="https://images.microbadger.com/badges/version/devilbox/php-fpm-7.3:mods-alpine.svg" /> <img src="https://images.microbadger.com/badges/image/devilbox/php-fpm-7.3:mods-alpine.svg" /><br/>
<img src="https://images.microbadger.com/badges/version/devilbox/php-fpm-7.3:mods-debian.svg" /> <img src="https://images.microbadger.com/badges/image/devilbox/php-fpm-7.3:mods-debian.svg" /> 
```shell
docker pull devilbox/php-fpm-7.3:mods-alpine
docker pull devilbox/php-fpm-7.3:mods-debian
```

Generic PHP-FPM image with fully loaded extensions. Use it to derive your own php-fpm docker image from it and add more extensions, tools and injectables.<br/><br/><sub>(Does not offer any environment variables except for `NEW_UID` and `NEW_GID`)</sub></td>

#### Image: prod
<img src="https://images.microbadger.com/badges/version/devilbox/php-fpm-7.3:prod-alpine.svg" /> <img src="https://images.microbadger.com/badges/image/devilbox/php-fpm-7.3:prod-alpine.svg" /><br/>
<img src="https://images.microbadger.com/badges/version/devilbox/php-fpm-7.3:prod-debian.svg" /> <img src="https://images.microbadger.com/badges/image/devilbox/php-fpm-7.3:prod-debian.svg" />
```shell
docker pull devilbox/php-fpm-7.3:prod-alpine
docker pull devilbox/php-fpm-7.3:prod-debian
```

Devilbox production image. This Docker image comes with many injectables, port-forwardings, mail-catch-all and user/group rewriting.

#### Image: work
<img src="https://images.microbadger.com/badges/version/devilbox/php-fpm-7.3:work-alpine.svg" /> <img src="https://images.microbadger.com/badges/image/devilbox/php-fpm-7.3:work-alpine.svg" /><br/>
<img src="https://images.microbadger.com/badges/version/devilbox/php-fpm-7.3:work-debian.svg" /> <img src="https://images.microbadger.com/badges/image/devilbox/php-fpm-7.3:work-debian.svg" /> 
```shell
docker pull devilbox/php-fpm-7.3:work-alpine
docker pull devilbox/php-fpm-7.3:work-debian
```

Devilbox development image. Same as prod, but comes with lots of locally installed tools to make development inside the container as convenient as possible. See [Integrated Development Environment](#integrated-development-environment) for more information about this.


<h2><img id="php-fpm-7.3-options" width="20" src="https://github.com/devilbox/artwork/raw/master/submissions_logo/cytopia/01/png/logo_64_trans.png"> PHP-FPM 7.3 Options</h2>

#### Environment variables

Have a look at the following table to see all supported environment variables for each Docker image flavour.

<table>
 <thead>
  <tr>
   <th>Image</th>
   <th>Env Variable</th>
   <th>Type</th>
   <th>Default</th>
   <th>Description</th>
  </tr>
 </thead>
 <tbody>
  <tr>
   <td rowspan="3"><strong>base</strong><br/><br/><strong>mods</strong><br/><br/><strong>prod</strong><br/><br/><strong>work</strong></td>
   <td><code>DEBUG_ENTRYPOINT</code></td>
   <td>int</td>
   <td><code>0</code></td>
   <td>Set debug level for startup.<br/><sub><code>0</code> Only warnings and errors are shown.<br/><code>1</code> All log messages are shown<br/><code>2</code> All log messages and executed commands are shown.</sub></td>
  </tr>
  <tr>
   <td><code>NEW_UID</code></td>
   <td>int</td>
   <td><code>1000</code></td>
   <td>Assign the PHP-FPM user a new <code>uid</code> in order to syncronize file system permissions with your host computer and the Docker container. You should use a value that matches your host systems local user.<br/><sub>(Type <code>id</code> for your uid).</sub></td>
  </tr>
  <tr>
   <td><code>NEW_GID</code></td>
   <td>int</td>
   <td><code>1000</code></td>
   <td>Assign the PHP-FPM group a new <code>gid</code> in order to syncronize file system permissions with your host computer and the Docker container. You should use a value that matches your host systems local group.<br/><sub>(Type <code>id</code> for your gid).</sub></td>
  </tr>
  <tr>
   <td colspan="5"></td>
  </tr>
  <tr>
   <td rowspan="4"><strong>prod</strong><br/><br/><strong>work</strong></td>
   <td><code>TIMEZONE</code></td>
   <td>string</td>
   <td><code>UTC</code></td>
   <td>Set docker OS timezone as well as PHP timezone.<br/>(Example: <code>Europe/Berlin</code>)</td>
  </tr>
  <tr>
   <td><code>DOCKER_LOGS</code></td>
   <td>bool</td>
   <td><code>1</code></td>
   <td>By default all Docker images are configured to output their PHP-FPM access and error logs to stdout and stderr. Those which support it can change the behaviour to log into files inside the container. Their respective directories are available as volumes that can be mounted to the host computer. This feature might help developer who are more comfortable with tailing or searching through actual files instead of using docker logs.<br/><br/>Set this variable to <code>0</code> in order to enable logging to files. Log files are avilable under <code>/var/log/php/</code> which is also a docker volume that can be mounted locally.</td>
  </tr>
  <tr>
   <td><code>ENABLE_MAIL</code></td>
   <td>bool</td>
   <td><code>0</code></td>
   <td>Enable local email catch-all.<br/>Postfix will be configured for local delivery and all mails sent (even to real domains) will be catched locally. No email will ever go out. They will all be stored in a local devilbox account.<br/>Value: <code>0</code> or <code>1</code></td>
  </tr>
  <tr>
   <td><code>FORWARD_PORTS_TO_LOCALHOST</code></td>
   <td>string</td>
   <td></td>
   <td>List of remote ports to forward to 127.0.0.1.<br/><strong>Format:</strong><br/><sub><code>&lt;local-port&gt;:&lt;remote-host&gt;:&lt;remote-port&gt;</code></sub><br/>You can separate multiple entries by comma.<br/><strong>Example:</strong><br/><sub><code>3306:mysqlhost:3306, 6379:192.0.1.1:6379</code></sub></td>
  </tr>
  <tr>
   <td colspan="5"></td>
  </tr>
  <tr>
   <td rowspan="3"><strong>work</strong></td>
   <td><code>MYSQL_BACKUP_USER</code></td>
   <td>string</td>
   <td><code>''</code></td>
   <td>Username for mysql backups used for bundled <a href="https://mysqldump-secure.org" >mysqldump-secure</a></td>
  </tr>
  <tr>
   <td><code>MYSQL_BACKUP_PASS</code></td>
   <td>string</td>
   <td><code>''</code></td>
   <td>Password for mysql backups used for bundled <a href="https://mysqldump-secure.org" >mysqldump-secure</a></td>
  </tr>
  <tr>
   <td><code>MYSQL_BACKUP_HOST</code></td>
   <td>string</td>
   <td><code>''</code></td>
   <td>Hostname for mysql backups used for bundled <a href="https://mysqldump-secure.org" >mysqldump-secure</a></td>
  </tr>
 </tbody>
</table>

#### Volumes

Have a look at the following table to see all offered volumes for each Docker image flavour.

<table>
 <thead>
  <tr>
   <th>Image</th>
   <th width="200">Volumes</th>
   <th>Description</th>
  </tr>
 </thead>
 <tbody>
  <tr>
   <td rowspan="4"><strong>prod</strong><br/><br/><strong>work</strong></td>
   <td><code>/etc/php-custom.d</code></td>
   <td>Mount this directory into your host computer and add custom <code>\*.ini</code> files in order to alter php behaviour.</td>
  </tr>
  <tr>
   <td><code>/etc/php-modules.d</code></td>
   <td>Mount this directory into your host computer and add custo <code>\*.so</code> files in order to add your php modules.<br/><br/><strong>Note:</strong>Your should then also provide a custom <code>\*.ini</code> file in order to actually load your custom provided module.</td>
  </tr>
  <tr>
   <td><code>/var/log/php</code></td>
   <td>When setting environment variable <code>DOCKER_LOGS</code> to <code>0</code>, log files will be available under this directory.</td>
  </tr>
  <tr>
   <td><code>/var/mail</code></td>
   <td>Emails caught be the postfix catch-all (<code>ENABLE_MAIL=1</code>) will be available in this directory.</td>
  </tr>
  <tr>
   <td colspan="3"></td>
  </tr>
  <tr>
   <td rowspan="1"><strong>work</strong></td>
   <td><code>/etc/bash-custom.d</code></td>
   <td>Mount this directory into your host computer and add custom configuration files for `bash` and other tools.</td>
  </tr>
 </tbody>
</table>


#### Ports

Have a look at the following table to see all offered exposed ports for each Docker image flavour.

<table>
 <thead>
  <tr>
   <th>Image</th>
   <th width="200">Port</th>
   <th>Description</th>
  </tr>
 </thead>
 <tbody>
  <tr>
   <td rowspan="1"><strong>base</strong><br/><strong>mods</strong><br/><strong>prod</strong><br/><strong>work</strong></td>
   <td><code>9000</code></td>
   <td>PHP-FPM listening port</td>
  </tr>
 </tbody>
</table>


<h2><img id="integrated-development-environment" width="20" src="https://github.com/devilbox/artwork/raw/master/submissions_logo/cytopia/01/png/logo_64_trans.png"> Integrated Development Environment</h2>

If you plan to use the PHP-FPM image for development, hence being able to execute common commands inside the container itself, you should go with the **work** Image.

The **work** Docker image has many common tools already installed which on one hand increases its image size, but on the other hand removes the necessity to install those tools locally.

You want to use tools such as `git`, `drush`, `composer`, `npm`, `eslint`, `phpcs` as well as many others, simply do it directly inside the container. As all Docker images are auto-built every night by travis-ci it is assured that you are always at the latest version of your favorite dev tool.


#### What tools can you expect

<table>
 <thead>
  <tr>
   <th width="200">Tool</th>
   <th>Description</th>
  </tr>
 </thead>
  <tr>
   <td><a href="https://github.com/cytopia/awesome-ci">awesome-ci</a></td>
   <td>Various linting and source code analyzing tools.</td>
  </tr>
  <tr>
   <td><a href="https://getcomposer.org">composer</a></td>
   <td>Dependency Manager for PHP.</td>
  </tr>
  <tr>
   <td><a href="https://drupalconsole.com">drupal-console</a></td>
   <td>The Drupal CLI. A tool to generate boilerplate code, interact with and debug Drupal.</td>
  </tr>
  <tr>
   <td><a href="http://www.drush.org">drush</a></td>
   <td>Drush is a computer software shell-based application used to control, manipulate, and administer Drupal websites.</td>
  </tr>
  <tr>
   <td><a href="https://eslint.org">eslint</a></td>
   <td>The pluggable linting utility for JavaScript and JSX.</td>
  </tr>
  <tr>
   <td><a href="https://git-scm.com">git</a></td>
   <td>Git is a version control system for tracking changes in source files.</td>
  </tr>
  <tr>
   <td><a href="https://github.com/laravel/installer">laravel installer</a></td>
   <td>A CLI tool to easily install and manage the laravel framework.</td>
  </tr>
  <tr>
   <td><a href="https://mysqldump-secure.org">mysqldump-secure</a></td>
   <td>Secury MySQL database backup tool with encryption.</td>
  </tr>
  <tr>
   <td><a href="https://nodejs.org">nodejs</a></td>
   <td>Node.js is an open-source, cross-platform JavaScript run-time environment for executing JavaScript code server-side.</td>
  </tr>
  <tr>
   <td><a href="https://www.npmjs.com">npm</a></td>
   <td>npm is a package manager for the JavaScript programming language.</td>
  </tr>
  <tr>
   <td><a href="https://github.com/phalcon/phalcon-devtools">phalcon-devtools</a></td>
   <td>CLI tool to generate code helping to develop faster and easy applications that use with Phalcon framework.</td>
  </tr>
  <tr>
   <td><a href="https://github.com/squizlabs/PHP_CodeSniffer">phpcs</a></td>
   <td>PHP_CodeSniffer tokenizes PHP, JavaScript and CSS files and detects violations of a defined set of coding standards..</td>
  </tr>
  <tr>
   <td><a href="(https://github.com/symfony/symfony-installer">symfony installer</a></td>
   <td>This is the official installer to start new projects based on the Symfony full-stack framework.</td>
  </tr>
  <tr>
   <td><a href="https://github.com/webpack/webpack">webpack</a></td>
   <td>A bundler for javascript and friends.</td>
  </tr>
  <tr>
   <td><a href="https://wp-cli.org">wp-cli</a></td>
   <td>WP-CLI is the command-line interface for WordPress.</td>
  </tr>
 <tbody>
 </tbody>
</table>

#### What else is available

Apart from the provided tools, you will also be able to use the container similar as you would do with your host system. Just a few things to mention here:

* Mount custom bash configuration files so your config persists between restarts
* Use password-less `sudo` to become root and do whatever you need to do

If there is anything else you'd like to be able to do, drop me an issue.


<h2><img id="examples" width="20" src="https://github.com/devilbox/artwork/raw/master/submissions_logo/cytopia/01/png/logo_64_trans.png"> Examples</h2>

#### Provide PHP-FPM port to host
```shell
$ docker run -d \
    -p 127.0.0.1:9000:9000 \
    -t devilbox/php-fpm-7.3:prod-debian
```

#### Alter PHP-FPM and system timezone
```shell
$ docker run -d \
    -p 127.0.0.1:9000:9000 \
    -e TIMEZONE=Europe/Berlin \
    -t devilbox/php-fpm-7.3:prod-debian
```

#### Load custom PHP configuration

`config/` is a local directory that will hold the PHP *.ini files you want to load into the Docker container.
```shell
# Create config directory to be mounted with dummy configuration
$ mkdir config
$ echo "xdebug.enable = 1" > config/xdebug.ini

# Run container and mount it
$ docker run -d \
    -p 127.0.0.1:9000:9000 \
    -v config:/etc/php-custom.d \
    -t devilbox/php-fpm-7.3:prod-debian
```

#### Load custom PHP modules

`modules/` is a local directory that will hold the PHP modules you want to mount into the Docker container. `config/` is a local directory that will hold the PHP *.ini files you want to load into the Docker container.

```shell
# Create module directory and place module into it
$ mkdir modules
$ cp /my/module/phalcon.so modules/

# Custom php config to load this module
$ mkdir config
$ echo "extension=/etc/php-modules.d/phalcon.so" > config/phalcon.ini

# Run container and mount it
$ docker run -d \
    -p 127.0.0.1:9000:9000 \
    -v config:/etc/php-custom.d \
    -v modules:/etc/php-modules.d \
    -t devilbox/php-fpm-7.3:prod-debian
```

#### MySQL connect via 127.0.0.1 (via port-forward)

Forward MySQL Port from `172.168.0.30` (or any other IP address/hostname) and Port `3306` to the PHP docker on `127.0.0.1:3306`. By this, your PHP files inside the docker can use `127.0.0.1` to connect to a MySQL database.
```shell
$ docker run -d \
    -p 127.0.0.1:9000:9000 \
    -e FORWARD_PORTS_TO_LOCALHOST='3306:172.168.0.30:3306' \
    -t devilbox/php-fpm-7.3:prod-debian
```

#### MySQL and Redis connect via 127.0.0.1 (via port-forward)

Forward MySQL Port from `172.168.0.30:3306` and Redis port from `redis:6379` to the PHP docker on `127.0.0.1:3306` and `127.0.0.1:6379`. By this, your PHP files inside the docker can use `127.0.0.1` to connect to a MySQL or Redis database.
```shell
$ docker run -d \
    -p 127.0.0.1:9000:9000 \
    -e FORWARD_PORTS_TO_LOCALHOST='3306:172.168.0.30:3306, 6379:redis:6379' \
    -t devilbox/php-fpm-7.3:prod-debian
```

#### Launch Postfix for mail-catching

Once you set `$ENABLE_MAIL=1`, all mails sent via any of your PHP applications no matter to which domain, are catched locally into the `devilbox` account. You can also mount the mail directory locally to hook in with mutt and read those mails.
```shell
$ docker run -d \
    -p 127.0.0.1:9000:9000 \
    -v /tmp/mail:/var/mail \
    -e ENABLE_MAIL=1 \
    -t devilbox/php-fpm-7.3:prod-debian
```

#### Webserver and PHP-FPM

`~/my-host-www` will be the directory that serves the php files (your document root). Make sure to mount it into both, php and the webserver.
```shell
# Start PHP-FPM container
$ docker run -d \
    -v ~/my-host-www:/var/www/default/htdocs \
    --name php \
    -t devilbox/php-fpm-7.3:prod-debian

# Start webserver and link with PHP-FPM
$ docker run -d \
    -p 80:80 \
    -v ~/my-host-www:/var/www/default/htdocs \
    -e PHP_FPM_ENABLE=1 \
    -e PHP_FPM_SERVER_ADDR=php \
    -e PHP_FPM_SERVER_PORT=9000 \
    --link php \
    -t devilbox/nginx-mainline
```


<h2><img id="automated-builds" width="20" src="https://github.com/devilbox/artwork/raw/master/submissions_logo/cytopia/01/png/logo_64_trans.png"> Automated builds</h2>

[![Build Status](https://travis-ci.org/devilbox/docker-php-fpm-7.3.svg?branch=master)](https://travis-ci.org/devilbox/docker-php-fpm-7.3)

Docker images are built and tested every night by **[travis-ci](https://travis-ci.org/devilbox/docker-php-fpm-7.3)** and pushed to **[Docker hub](https://hub.docker.com/r/devilbox/php-fpm-7.3/)** on success. This is all done automatically to ensure that sources as well as base images are always fresh and in case of security updates always have the latest patches.

<h2><img id="contributing" width="20" src="https://github.com/devilbox/artwork/raw/master/submissions_logo/cytopia/01/png/logo_64_trans.png"> Contributing</h2>

Contributors are welcome. Feel free to star and clone this repository and submit issues and pull-requests. Add examples and show what you have created with the provided images. If you see any errors or ways to improve this repository in any way, please do so.

<h2><img id="credits" width="20" src="https://github.com/devilbox/artwork/raw/master/submissions_logo/cytopia/01/png/logo_64_trans.png"> Credits</h2>

* **[cytopia](https://github.com/cytopia)**

<h2><img id="license" width="20" src="https://github.com/devilbox/artwork/raw/master/submissions_logo/cytopia/01/png/logo_64_trans.png"> License</h2>

**[MIT License](LICENSE.md)**

Copyright (c) 2017 [cytopia](https://github.com/cytopia)

