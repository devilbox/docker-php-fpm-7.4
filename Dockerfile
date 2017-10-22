FROM debian:latest
MAINTAINER "cytopia" <cytopia@everythingcli.org>


###
### Labels
###
LABEL \
	name="cytopia's PHP-FPM 7.3 Image" \
	image="docker-php-fpm-7.3" \
	vendor="devilbox" \
	license="MIT" \
	build-date="2017-10-22"



###
### Build Args
###
ARG PHP_GIT_BRANCH=master
ARG PHP_CONF_INI_DIR=/etc
ARG PHP_CONF_ADD_DIR=/etc/php.d



###
### Envs
###
ENV MY_USER="devilbox" \
	MY_GROUP="devilbox" \
	MY_UID="1000" \
	MY_GID="1000"



###
### Pre-Setup
###

# User/Group
RUN set -x \
	&& groupadd -g ${MY_GID} -r ${MY_GROUP} \
	&& useradd -u ${MY_UID} -m -s /bin/bash -g ${MY_GROUP} ${MY_USER}



###
### Installation
###

# Required for git
RUN set -x \
	&& apt-get update \
	&& apt-get upgrade -y \
	&& apt-get install --no-install-recommends --no-install-suggests -y \
		git \
		ca-certificates \
	&& rm -rf /var/lib/apt/lists/* \
	&& apt-get purge -y --auto-remove

# Required to build
RUN set -x \
	&& apt-get update \
	&& apt-get install --no-install-recommends --no-install-suggests -y \
		autoconf \
		bison \
		file \
		locales \
		make \
		g++ \
		gcc \
		g++-6 \
		gcc-6 \
		re2c \
	&& rm -rf /var/lib/apt/lists/* \
	&& apt-get purge -y --auto-remove

# Required libs for php
RUN set -x \
	&& apt-get update \
	&& apt-get install --no-install-recommends --no-install-suggests -y \
		firebird-dev \
		libaspell-dev \
		libbz2-dev \
		libc-client-dev \
		libcurl4-openssl-dev \
		libenchant-dev \
		libfbclient2 \
		libfreetype6-dev \
		libgmp-dev \
		libib-util \
		libicu-dev \
		libjpeg-dev \
		libkrb5-dev \
		libldap2-dev \
		libldb-dev \
		libmcrypt-dev \
		libpcre3-dev \
		libpng-dev \
		libpq-dev \
		libpspell-dev \
		libreadline-dev \
		librecode-dev \
		libsasl2-dev \
		libsnmp-dev \
		libssl-dev \
		libtidy-dev \
		libwebp-dev \
		libxml2-dev \
		libxpm-dev \
		libxslt-dev \
		libzip-dev \
		snmp \
	&& rm -rf /var/lib/apt/lists/* \
	&& apt-get purge -y --auto-remove

# Fix ldap linked libs
RUN set -x \
	&& ln -s /usr/lib/x86_64-linux-gnu/libldap* /usr/lib/ \
	&& ln -s /usr/lib/x86_64-linux-gnu/liblber* /usr/lib/ \
	&& ln -s /usr/lib/x86_64-linux-gnu/libpcre* /usr/lib/

# Get php sources
RUN set -x \
	&& mkdir -p /usr/local/src \
	&& git clone -v https://github.com/php/php-src /usr/local/src/php-src \
	&& cd /usr/local/src/php-src \
	&& git checkout ${PHP_GIT_BRANCH}

# Configure php sources
RUN set -x \
	&& cd /usr/local/src/php-src \
	&& ./buildconf --force \
	&& ./configure \
		\
		--enable-static=yes \
		--enable-shared=no \
		\
		--prefix=/usr \
		--exec-prefix=/usr \
		--sysconfdir=${PHP_CONF_INI_DIR} \
		--with-config-file-path=${PHP_CONF_INI_DIR} \
		--with-config-file-scan-dir=${PHP_CONF_ADD_DIR} \
		--mandir=/usr/share/man \
		\
		--enable-bcmath \
		--enable-calendar \
		--enable-exif \
		--enable-fpm \
		--enable-ftp \
		--enable-gd-jis-conv \
		--enable-intl \
		--enable-mbstring \
		--enable-mysqlnd \
		--enable-pcntl \
		--enable-shmop \
		--enable-soap \
		--enable-sockets \
		--enable-sysvmsg \
		--enable-sysvsem \
		--enable-sysvshm \
		--enable-wddx \
		--enable-xmlreader \
		--enable-zip \
		\
		--with-pear \
		\
		--with-fpm-user=${MY_USER} \
		--with-fpm-group=${MY_GROUP} \
		\
		--with-freetype-dir=/usr \
		--with-iconv-dir=/usr \
		--with-icu-dir=/usr \
		--with-jpeg-dir=/usr \
		--with-libxml-dir=/usr \
		--with-openssl-dir=/usr \
		--with-pcre-dir=/usr \
		--with-png-dir=/usr \
		--with-webp-dir=/usr \
		--with-xpm-dir=/usr \
		--with-zlib-dir=/usr \
		\
		--with-bz2 \
		--with-curl=/usr \
		--with-enchant=/usr \
		--with-gd \
		--with-gettext \
		--with-gmp \
		--with-imap \
		--with-imap-ssl \
		--with-interbase=/usr \
		--with-kerberos \
		--with-ldap=/usr \
		--with-ldap-sasl=/usr \
		--with-libzip=/usr \
		--with-mhash \
		--with-mysqli=mysqlnd \
		--with-openssl \
		--with-pcre-regex=/usr \
		--with-pcre-jit \
		--with-pdo-firebird \
		--with-pdo-mysql=mysqlnd \
		--with-pdo-pgsql \
		--with-pdo-sqlite \
		--with-pgsql \
		--with-pspell=/usr \
		--with-readline \
		--with-snmp=/usr \
		--with-tidy \
		--with-xmlrpc \
		--with-xsl \
		--with-zlib

# Build php sources
RUN set -x \
	&& cd /usr/local/src/php-src \
	&& make -j$(getconf _NPROCESSORS_ONLN) \
	&& make install

# Post configuration
RUN set -x \
	&& mkdir -p ${PHP_CONF_INI_DIR} \
	&& mkdir -p ${PHP_CONF_ADD_DIR} \
	&& cp /usr/local/src/php-src/php.ini-development ${PHP_CONF_INI_DIR}/php.ini

# Pear configuration
RUN set -x \
	&& touch ${PHP_CONF_ADD_DIR}/php-pecl.ini \
	&& pecl config-set php_ini ${PHP_CONF_ADD_DIR}/php-pecl.ini \
	&& pecl channel-update pecl.php.net \
	&& pecl update-channels

# Pear requirements
RUN set -x \
	&& apt-get update \
	&& apt-get install --no-install-recommends --no-install-suggests -y \
		libmemcached-dev \
		librabbitmq-dev \
		libmagickwand-dev \
	&& rm -rf /var/lib/apt/lists/* \
	&& apt-get purge -y --auto-remove

# Pear packages
RUN set -x \
	&& pecl install amqp \
	&& pecl install igbinary \
	&& pecl install imagick \
	&& pecl install memcached \
	&& pecl install mongodb \
	&& pecl install msgpack \
	&& pecl install redis \
	\
	&& echo "extension=amqp.so" > ${PHP_CONF_ADD_DIR}/amqp.ini \
	&& echo "extension=igbinary.so" > ${PHP_CONF_ADD_DIR}/igbinary.ini \
	&& echo "extension=imagick.so" > ${PHP_CONF_ADD_DIR}/imagick.ini \
	&& echo "extension=memcached.so" > ${PHP_CONF_ADD_DIR}/memcached.ini \
	&& echo "extension=mongodb.so" > ${PHP_CONF_ADD_DIR}/mongodb.ini \
	&& echo "extension=msgpack.so" > ${PHP_CONF_ADD_DIR}/msgpack.ini \
	&& echo "extension=redis.so" > ${PHP_CONF_ADD_DIR}/redis.ini



###
### Configuration
###

# PHP-FPM
RUN set -x \
	&& { \
		echo "[global]"; \
		echo "error_log = /proc/self/fd/2"; \
		echo "log_level = notice"; \
		echo "daemonize = no"; \
		echo "include   = /etc/php-fpm.d/*.conf"; \
	} | tee /etc/php-fpm.conf \
	\
	&& mv /etc/php-fpm.d/www.conf.default /etc/php-fpm.d/01-www.conf \
	\
	&& { \
		echo "[www]"; \
		echo "; if we send this to /proc/self/fd/1, it never appears"; \
		echo "access.log = /proc/self/fd/2"; \
		\
		echo "listen = [::]:9000"; \
		\
		echo "; Keep env variables set by docker"; \
		echo "clear_env = no"; \
		\
		echo "; Ensure worker stdout and stderr are sent to the main error log."; \
		echo "catch_workers_output = yes"; \
	} | tee /etc/php-fpm.d/99-docker.conf



###
### Clean-up
###
RUN set -x \
	&& apt-get update \
	&& apt-get remove -y \
		autoconf \
		bison \
		ca-certificates \
		file \
		git \
		locales \
		make \
		g++ \
		gcc \
		g++-6 \
		gcc-6 \
		re2c \
		snmp \
	&& apt-get autoremove -y \
	&& rm -rf /var/lib/apt/lists/* \
	&& apt-get purge -y --auto-remove \
	\
	&& rm -rf /media \
	&& rm -rf /mnt \
	&& rm -rf /opt \
	&& rm -rf /root/.pearrc \
	&& rm -rf /srv \
	&& rm -rf /tmp/* \
	&& rm -rf /usr/games \
	&& rm -rf /usr/local \
	&& rm -rf /usr/php \
	&& rm -rf /usr/share/doc \
	&& rm -rf /usr/share/icons \
	&& rm -rf /usr/share/man \
	&& rm -rf /usr/src



###
### Verify
###
RUN set -x \
	&& /usr/sbin/php-fpm --test



###
### Ports
###
EXPOSE 9000



###
### Entrypoint
###
ENTRYPOINT ["/usr/sbin/php-fpm"]
