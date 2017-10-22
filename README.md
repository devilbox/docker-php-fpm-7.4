# PHP-FPM 7.3 Docker

Fully functional PHP-FPM 7.3 Docker image with loads of modules included.



## Options

### Environment variables

None

### Default ports

| Docker | Description |
|--------|-------------|
| 9000   | PHP-FPM listening Port |



## TODO

This Docker image has already been tested and works as expected, however for now this is just a proof of concept version and the image is still relatively big. So there is some work to do in order to improve it.

* Improve Docker file
* Shrink the Docker image
* Build PHP statically



## Modules

**[Version]**

PHP 7.3.0-dev (cli) (built: Oct 22 2017 09:29:46) ( NTS )
Copyright (c) 1997-2017 The PHP Group
Zend Engine v3.3.0-dev, Copyright (c) 1998-2017 Zend Technologies

**[PHP Modules]**

amqp, bcmath, bz2, calendar, Core, ctype, curl, date, dom, enchant, exif, fileinfo, filter, ftp, gd, gettext, gmp, hash, iconv, igbinary, imagick, imap, interbase, intl, json, ldap, libxml, mbstring, memcached, mongodb, msgpack, mysqli, mysqlnd, openssl, pcntl, pcre, PDO, PDO_Firebird, pdo_mysql, pdo_pgsql, pdo_sqlite, pgsql, Phar, posix, pspell, readline, redis, Reflection, session, shmop, SimpleXML, snmp, soap, sockets, SPL, sqlite3, standard, sysvmsg, sysvsem, sysvshm, tidy, tokenizer, wddx, xml, xmlreader, xmlrpc, xmlwriter, xsl, zip, zlib

**[Zend Modules]**
