#!/usr/bin/with-contenv sh


# Prevent continue script after exit code 1.
set -e


# Define document root of PHP app.
APP_DIR="/var/www/html"


# Check if docker running in test mode (only for debug).
if [ "$TEST_MODE" = true ]; then
    APP_PUBLIC_DIR=""
else
    rm -rf ${APP_DIR}/tests
fi


### NGINX ###
# Customize NGINX configuration.
sed -i \
    -e "s@base /<APP_DIR>;@base ${APP_DIR};@" \
    -e "s@base/<APP_PUBLIC_DIR>;@base/${APP_PUBLIC_DIR};@" \
    -e "s/client_max_body_size 32M;/client_max_body_size ${PHP_UPLOAD_MAX_FILESIZE};/" \
    -e "s@include app-layouts/default.conf;@include app-layouts/${APP_LAYOUT}.conf;@" \
    /etc/nginx/nginx-site.conf
sed -i \
    -e "s/fastcgi_read_timeout    30;/fastcgi_read_timeout    ${PHP_MAX_EXECUTION_TIME};/" \
    /etc/nginx/php-fastcgi.conf

# Fix Nginx user permissions.
if [ "$(id -u nginx)" != "$APP_UID" ] || [ "$(id -g nginx)" != "$APP_GID" ]; then
    deluser nginx
    addgroup -g "$APP_GID" nginx
    adduser -D -S -h /var/cache/nginx -s /sbin/nologin -G nginx -u "$APP_UID" nginx
fi

# Fix dirs user permissions.
mkdir -p "$APP_DIR"
mkdir -p ${APP_DIR}/${APP_PUBLIC_DIR}
chown -Rf nginx:nginx "$APP_DIR"
### END NGINX ###


### PHP ###
# Function for add rule row into specific .ini file.
add_php_config() {
    ini="/usr/local/etc/php/conf.d/docker-php-$2.ini"
    if ! grep -q "$1" "$ini" 2>/dev/null; then
		echo "$1" >> "$ini"
	fi
}

# Tweak php configuration.
add_php_config cgi.fix_pathinfo=0 general
add_php_config expose_php=Off general
add_php_config max_input_time=60 general
add_php_config output_buffering=4096 general
add_php_config register_argc_argv=Off general
add_php_config request_order="GP" general
add_php_config session.gc_divisor=1000 general
add_php_config session.sid_bits_per_character=5 general
add_php_config short_open_tag=Off general
add_php_config variables_order="GPCS" general
add_php_config max_execution_time="$PHP_MAX_EXECUTION_TIME" general
add_php_config upload_max_filesize="$PHP_UPLOAD_MAX_FILESIZE" general
add_php_config post_max_size="$PHP_UPLOAD_MAX_FILESIZE" general
add_php_config memory_limit="$PHP_MEM_LIMIT" general

add_php_config opcache.enable_cli=1 opcache
add_php_config opcache.enable_file_override=1 opcache
add_php_config opcache.fast_shutdown=1 opcache
add_php_config opcache.huge_code_pages=1 opcache
add_php_config opcache.interned_strings_buffer=16 opcache
add_php_config opcache.max_accelerated_files=7963 opcache
add_php_config opcache.memory_consumption=192 opcache
add_php_config opcache.revalidate_freq=0 opcache
add_php_config opcache.save_comments=1 opcache
#add_php_config opcache.preload=${APP_DIR}/${APP_PUBLIC_DIR}/index.php opcache

# Optimize php configuration for dev/prod.
if [ "$APP_ENV" = "prod" ]; then
    add_php_config display_errors=Off general
    add_php_config mysqlnd.collect_memory_statistics=Off general
    add_php_config zend.assertions=-1 general
    add_php_config opcache.validate_timestamps=0 opcache
else
    add_php_config display_startup_errors=On general
fi

# Configure PHP-FPM configuration.
sed -i \
    -e "s/;catch_workers_output\s*=\s*yes/catch_workers_output = yes/g" \
    -e "s/pm.max_children = 5/pm.max_children = 9/g" \
    -e "s/pm.start_servers = 2/pm.start_servers = 3/g" \
    -e "s/pm.min_spare_servers = 1/pm.min_spare_servers = 2/g" \
    -e "s/pm.max_spare_servers = 3/pm.max_spare_servers = 4/g" \
    -e "s/;pm.max_requests = 500/pm.max_requests = 200/g" \
    -e "s/user = www-data/user = nginx/g" \
    -e "s/group = www-data/group = nginx/g" \
    -e "s/;listen.mode = 0660/listen.mode = 0666/g" \
    -e "s/;listen.owner = www-data/listen.owner = nginx/g" \
    -e "s/;listen.group = www-data/listen.group = nginx/g" \
    -e "s/listen = 127.0.0.1:9000/listen = \/var\/run\/php-fpm.sock/g" \
    -e "s/^;clear_env = no$/clear_env = no/" \
    /usr/local/etc/php-fpm.d/www.conf
### END PHP ###
