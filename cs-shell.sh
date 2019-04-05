#!/bin/bash

# Check.
# https://github.com/koalaman/shellcheck

shellcheck ./*.sh
shellcheck -e SC1008 ./content/s6-overlay/cont-init.d/*.sh
shellcheck ./base-php-fpm/docker-php-source
shellcheck ./cs-shell.sh
shellcheck ./cs-nginx.sh
shellcheck ./cs-php.sh


# Fix.
# https://github.com/lovesegfault/beautysh
beautysh -f ./build.sh ./cs-shell.sh ./cs-nginx.sh ./cs-php.sh ./base-php-fpm/docker-php-source
