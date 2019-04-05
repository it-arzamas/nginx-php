######################################################################################################################
### BASE IMAGE AND TAG
### This arguments specifies the base of this build.
### https://wiki.alpinelinux.org/wiki/Alpine_Linux:Releases
### https://hub.docker.com/_/php?tab=description#supported-tags-and-respective-dockerfile-links
######################################################################################################################
ARG BASE_IMAGE=php
ARG BASE_TAG=7.3-fpm-alpine3.9
######################################################################################################################
### @END@ BASE IMAGE AND TAG
######################################################################################################################


FROM ${BASE_IMAGE}:${BASE_TAG}

MAINTAINER Ondřej Misák <email@ondrejmisak.cz>


######################################################################################################################
### NGINX VERSION
### This variable specifies the NGINX version.
### https://github.com/nginx/nginx/releases
######################################################################################################################
ENV NGINX_VERSION 1.15.10
######################################################################################################################
### @END@ NGINX VERSION
######################################################################################################################


######################################################################################################################
### S6 OVERLAY VERSION
### This variable specifies the S6 OVERLAY version.
### https://github.com/just-containers/s6-overlay/releases
######################################################################################################################
ENV S6_OVERLAY_VER 1.22.1.0
######################################################################################################################
### @END@ S6 OVERLAY VERSION
######################################################################################################################


######################################################################################################################
### PHP PECL PACKAGES
### Follow arguments specifies the versions of the pecl packages.
### https://pecl.php.net/package/memcached
######################################################################################################################
ARG PECL_MEMCACHED_VERSION=3.1.3
######################################################################################################################
### @END@ PHP PECL PACKAGES
######################################################################################################################


######################################################################################################################
### TEST MODE
### Set true only if you like to test this base docker image correct functionality!
######################################################################################################################
ARG TEST_MODE=false
######################################################################################################################
### @END@ TEST MODE
######################################################################################################################


######################################################################################################################
### DEFAULT SYSTEM CONFIGURATION AND USER/GROUP PERMISSIONS
### APP_ENV = production or development (prod|dev) switcher.
### APP_UID = owner (user id) of files in your app.
### APP_GID = owner (group id) of files in your app.
### APP_TZ  = system and PHP time-zone (https://en.wikipedia.org/wiki/List_of_tz_database_time_zones)
######################################################################################################################
ENV APP_ENV prod
ENV APP_UID 1000
ENV APP_GID 1000
ENV APP_TZ Europe/Prague
######################################################################################################################
### @END@ DEFAULT SYSTEM CONFIGURATION AND USER/GROUP PERMISSIONS
######################################################################################################################


######################################################################################################################
### APP LAYOUT
### App layout is the default configuration of NGINX and PHP specifically for running these platforms.
### default     = (default) this layer is suitable for most applications.
### wordpress   = this layer is good for running wordpress websites.
### drupal      = this layer is good for running drupal websites.
### magento     = this layer is suitable for magento eshop running.
######################################################################################################################
ENV APP_LAYOUT default
######################################################################################################################
### @END@ APP LAYOUT
######################################################################################################################


######################################################################################################################
### DEFAULT NGINX CONFIGURATION
### APP_PUBLIC_DIR = document root of your app. Default path is /app/public.
######################################################################################################################
ENV APP_PUBLIC_DIR ''
######################################################################################################################
### @END@ DEFAULT NGINX CONFIGURATION
######################################################################################################################


######################################################################################################################
### PHP CONFIGURATION
### PHP_MEM_LIMIT           = max RAM limit for PHP.
### PHP_UPLOAD_MAX_FILESIZE = upload limit. The same value is also applied to the NGINX parameter nginx client_max_body_size.
### PHP_MAX_EXECUTION_TIME  = script run time limit (sec). The same value is also applied to the NGINX parameter nginx fastcgi_read_timeout.
######################################################################################################################
ENV PHP_MEM_LIMIT 128M
ENV PHP_UPLOAD_MAX_FILESIZE 32M
ENV PHP_MAX_EXECUTION_TIME 30
######################################################################################################################
### @END@ PHP CONFIGURATION
######################################################################################################################


### Fix Alpine linux libiconv missing package (issue #240: https://github.com/docker-library/php/issues/240).
ENV LD_PRELOAD /usr/lib/preloadable_libiconv.so php
RUN apk add --no-cache --repository http://dl-3.alpinelinux.org/alpine/edge/community gnu-libiconv


######################################################################################################################
### NGINX PART
### This part is copied from the official repository Nginx.
### Please do not change the settings! The part of the code will be overwritten when updating the Nginx dockerfile.
### https://github.com/nginxinc/docker-nginx/blob/2364fdc54af554d28ef95b7be381677d10987986/mainline/alpine/Dockerfile
######################################################################################################################
RUN GPG_KEYS=B0F4253373F8F6F510D42178520A9993A1C052F8 \
	&& CONFIG="\
		--prefix=/etc/nginx \
		--sbin-path=/usr/sbin/nginx \
		--modules-path=/usr/lib/nginx/modules \
		--conf-path=/etc/nginx/nginx.conf \
		--error-log-path=/var/log/nginx/error.log \
		--http-log-path=/var/log/nginx/access.log \
		--pid-path=/var/run/nginx.pid \
		--lock-path=/var/run/nginx.lock \
		--http-client-body-temp-path=/var/cache/nginx/client_temp \
		--http-proxy-temp-path=/var/cache/nginx/proxy_temp \
		--http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
		--http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
		--http-scgi-temp-path=/var/cache/nginx/scgi_temp \
		--user=nginx \
		--group=nginx \
		--with-http_ssl_module \
		--with-http_realip_module \
		--with-http_addition_module \
		--with-http_sub_module \
		--with-http_dav_module \
		--with-http_flv_module \
		--with-http_mp4_module \
		--with-http_gunzip_module \
		--with-http_gzip_static_module \
		--with-http_random_index_module \
		--with-http_secure_link_module \
		--with-http_stub_status_module \
		--with-http_auth_request_module \
		--with-http_xslt_module=dynamic \
		--with-http_image_filter_module=dynamic \
		--with-http_geoip_module=dynamic \
		--with-threads \
		--with-stream \
		--with-stream_ssl_module \
		--with-stream_ssl_preread_module \
		--with-stream_realip_module \
		--with-stream_geoip_module=dynamic \
		--with-http_slice_module \
		--with-mail \
		--with-mail_ssl_module \
		--with-compat \
		--with-file-aio \
		--with-http_v2_module \
	" \
	&& addgroup -S nginx \
	&& adduser -D -S -h /var/cache/nginx -s /sbin/nologin -G nginx nginx \
	&& apk add --no-cache --virtual .build-deps \
		gcc \
		libc-dev \
		make \
		openssl-dev \
		pcre-dev \
		zlib-dev \
		linux-headers \
		curl \
		gnupg1 \
		libxslt-dev \
		gd-dev \
		geoip-dev \
	&& curl -fSL https://nginx.org/download/nginx-$NGINX_VERSION.tar.gz -o nginx.tar.gz \
	&& curl -fSL https://nginx.org/download/nginx-$NGINX_VERSION.tar.gz.asc  -o nginx.tar.gz.asc \
	&& export GNUPGHOME="$(mktemp -d)" \
	&& found=''; \
	for server in \
		ha.pool.sks-keyservers.net \
		hkp://keyserver.ubuntu.com:80 \
		hkp://p80.pool.sks-keyservers.net:80 \
		pgp.mit.edu \
	; do \
		echo "Fetching GPG key $GPG_KEYS from $server"; \
		gpg --keyserver "$server" --keyserver-options timeout=10 --recv-keys "$GPG_KEYS" && found=yes && break; \
	done; \
	test -z "$found" && echo >&2 "error: failed to fetch GPG key $GPG_KEYS" && exit 1; \
	gpg --batch --verify nginx.tar.gz.asc nginx.tar.gz \
	&& rm -rf "$GNUPGHOME" nginx.tar.gz.asc \
	&& mkdir -p /usr/src \
	&& tar -zxC /usr/src -f nginx.tar.gz \
	&& rm nginx.tar.gz \
	&& cd /usr/src/nginx-$NGINX_VERSION \
	&& ./configure $CONFIG --with-debug \
	&& make -j$(getconf _NPROCESSORS_ONLN) \
	&& mv objs/nginx objs/nginx-debug \
	&& mv objs/ngx_http_xslt_filter_module.so objs/ngx_http_xslt_filter_module-debug.so \
	&& mv objs/ngx_http_image_filter_module.so objs/ngx_http_image_filter_module-debug.so \
	&& mv objs/ngx_http_geoip_module.so objs/ngx_http_geoip_module-debug.so \
	&& mv objs/ngx_stream_geoip_module.so objs/ngx_stream_geoip_module-debug.so \
	&& ./configure $CONFIG \
	&& make -j$(getconf _NPROCESSORS_ONLN) \
	&& make install \
	&& rm -rf /etc/nginx/html/ \
	&& mkdir /etc/nginx/conf.d/ \
	&& mkdir -p /usr/share/nginx/html/ \
	&& install -m644 html/index.html /usr/share/nginx/html/ \
	&& install -m644 html/50x.html /usr/share/nginx/html/ \
	&& install -m755 objs/nginx-debug /usr/sbin/nginx-debug \
	&& install -m755 objs/ngx_http_xslt_filter_module-debug.so /usr/lib/nginx/modules/ngx_http_xslt_filter_module-debug.so \
	&& install -m755 objs/ngx_http_image_filter_module-debug.so /usr/lib/nginx/modules/ngx_http_image_filter_module-debug.so \
	&& install -m755 objs/ngx_http_geoip_module-debug.so /usr/lib/nginx/modules/ngx_http_geoip_module-debug.so \
	&& install -m755 objs/ngx_stream_geoip_module-debug.so /usr/lib/nginx/modules/ngx_stream_geoip_module-debug.so \
	&& ln -s ../../usr/lib/nginx/modules /etc/nginx/modules \
	&& strip /usr/sbin/nginx* \
	&& strip /usr/lib/nginx/modules/*.so \
	&& rm -rf /usr/src/nginx-$NGINX_VERSION \
	\
	# Bring in gettext so we can get `envsubst`, then throw
	# the rest away. To do this, we need to install `gettext`
	# then move `envsubst` out of the way so `gettext` can
	# be deleted completely, then move `envsubst` back.
	&& apk add --no-cache --virtual .gettext gettext \
	&& mv /usr/bin/envsubst /tmp/ \
	\
	&& runDeps="$( \
		scanelf --needed --nobanner --format '%n#p' /usr/sbin/nginx /usr/lib/nginx/modules/*.so /tmp/envsubst \
			| tr ',' '\n' \
			| sort -u \
			| awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
	)" \
	&& apk add --no-cache --virtual .nginx-rundeps $runDeps \
	&& apk del .build-deps \
	&& apk del .gettext \
	&& mv /tmp/envsubst /usr/local/bin/ \
	\
	# Bring in tzdata so users could set the timezones through the environment
	# variables
	&& apk add --no-cache tzdata \
	\
	# forward request and error logs to docker log collector
	&& ln -sf /dev/stdout /var/log/nginx/access.log \
	&& ln -sf /dev/stderr /var/log/nginx/error.log
######################################################################################################################
### @END@ NGINX PART
######################################################################################################################


######################################################################################################################
### PHP PART
### This section is used to install and configure PHP modules and the necessary libraries.
### https://docs.docker.com/samples/library/php/
######################################################################################################################
RUN set -ex \
    && apk add --no-cache --virtual .build-deps \
        $PHPIZE_DEPS \
        # PHP intl extension
        icu-dev \
        # PHP GD extension
        libpng-dev \
        libjpeg-turbo-dev \
        freetype-dev \
        # PHP memcached extension
        zlib-dev \
        libmemcached-dev \
        cyrus-sasl-dev \
        # PHP zip extension
        libzip-dev

RUN set -ex \
    && cd /usr/src \
    && docker-php-ext-configure intl --with-intl \
    && docker-php-ext-configure gd \
        --with-freetype-dir=/usr \
        --with-png-dir=/usr \
        --with-jpeg-dir=/usr \
    && docker-php-ext-install -j$(nproc) \
        gd \
        iconv \
        intl \
        mysqli \
        opcache \
#        pdo \
#        pdo_mysql \
        zip \
    && pecl install memcached-${PECL_MEMCACHED_VERSION} \
    && docker-php-ext-enable memcached \
    && runDeps="$( \
    		scanelf --needed --nobanner --format '%n#p' --recursive /usr/local/lib/php/extensions \
    			| tr ',' '\n' \
    			| sort -u \
    			| awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
    	)" \
    && apk add --virtual .phpexts-rundeps $runDeps \
    && docker-php-source delete
######################################################################################################################
### @END@ PHP PART
######################################################################################################################


######################################################################################################################
### S6 OVERLAY PART
### The s6-overlay-builder project is a series of init scripts and utilities to ease creating Docker images
### using s6 as a process supervisor.
### https://github.com/just-containers/s6-overlay
######################################################################################################################
RUN set -ex \
    && cd /tmp \
    && wget -O - https://github.com/just-containers/s6-overlay/releases/download/v$S6_OVERLAY_VER/s6-overlay-amd64.tar.gz \
    | tar xvzf - -C /
######################################################################################################################
### @END@ S6 OVERLAY PART
######################################################################################################################


######################################################################################################################
### SYSTEM CONFIGURATION PART
### This section is for configuring the Alpine system.
######################################################################################################################
RUN set -ex \
    # Set timezone.
    && cp /usr/share/zoneinfo/$APP_TZ /etc/localtime \
    \
    # Prepare file-system
    && rm -Rf /var/www/* \
    && mkdir /var/www/html \
    && mkdir -p /var/www/html/tests \
    \
    # Clean up!
    && apk del .build-deps \
    && rm -rf /usr/share/nginx/html \
    && rm -rf /usr/src/php.tar.xz* \
    && rm -rf /usr/local/bin/docker-php-ext-* \
    && rm -rf /tmp/* \
    && rm -rf /var/cache/apk/*
######################################################################################################################
### @END@ SYSTEM CONFIGURATION PART
######################################################################################################################


COPY --chown=nginx:nginx content/nginx /etc/nginx
COPY --chown=root:root content/s6-overlay/cont-init.d /etc/cont-init.d
COPY --chown=root:root content/s6-overlay/services.d /etc/services.d
COPY --chown=nginx:nginx content/demo/index.php /var/www/html/index.php
COPY --chown=nginx:nginx content/tests /var/www/html/tests


### Expose NGINX port.
EXPOSE 80


### Run S6 OVERLAY initialization script.
ENTRYPOINT ["/init"]
