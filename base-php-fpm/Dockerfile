FROM alpine:3.9

MAINTAINER Ondřej Misák <email@ondrejmisak.cz>

ENV PHPIZE_DEPS \
		autoconf \
		dpkg-dev dpkg \
		file \
		g++ \
		gcc \
		libc-dev \
		make \
		pkgconf \
		re2c

RUN set -x \
	&& addgroup -g 82 -S www-data \
	&& adduser -u 82 -D -S -G www-data www-data

ENV PHP_INI_DIR /usr/local/etc/php
RUN set -eux; \
	mkdir -p "$PHP_INI_DIR/conf.d"; \
	[ ! -d /var/www/html ]; \
	mkdir -p /var/www/html; \
	chown www-data:www-data /var/www/html; \
	chmod 777 /var/www/html

ADD --chown=root:root ./docker-php-source /usr/local/bin/
ADD --chown=root:root https://raw.githubusercontent.com/docker-library/php/bb16de8a711d1ba1dc76adf4665b3b1c06a06922/docker-php-entrypoint /usr/local/bin/
ADD --chown=root:root https://raw.githubusercontent.com/docker-library/php/bb16de8a711d1ba1dc76adf4665b3b1c06a06922/docker-php-ext-configure /usr/local/bin/
ADD --chown=root:root https://raw.githubusercontent.com/docker-library/php/bb16de8a711d1ba1dc76adf4665b3b1c06a06922/docker-php-ext-enable /usr/local/bin/
ADD --chown=root:root https://raw.githubusercontent.com/docker-library/php/bb16de8a711d1ba1dc76adf4665b3b1c06a06922/docker-php-ext-install /usr/local/bin/

RUN set -ex \
	&& chmod +x /usr/local/bin/docker-php-*

ENV PHP_EXTRA_CONFIGURE_ARGS --enable-fpm --with-fpm-user=www-data --with-fpm-group=www-data --disable-cgi
ENV PHP_CFLAGS="-fstack-protector-strong -fpic -fpie -O2"
ENV PHP_CPPFLAGS="$PHP_CFLAGS"
ENV PHP_LDFLAGS="-Wl,-O1 -Wl,--hash-style=both -pie"

WORKDIR /var/www/html
