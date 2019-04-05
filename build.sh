#!/bin/bash

buildTestAndPush() {
    truncateImageName=${1/\//-}
    truncateImageName=${truncateImageName/:/-}

    docker build --squash $2 -t $1 .

    if [[ $? -eq 0 ]]
    then
      echo "Docker image ${1} build success." >&2
    else
      echo "Docker image ${1} build failed." >&2
      exit 1
    fi

    docker run -d -p 80:80 -e "TEST_MODE=true" --name ${truncateImageName} $1
    sleep 3
    yarn run docker-test-running

    if [[ $? -eq 0 ]]
    then
      docker push $1
    else
      echo "Docker image ${1} test failed." >&2
      exit 1
    fi

    docker stop ${truncateImageName}
    docker rm ${truncateImageName}
    docker rmi $1
}


case "$1" in
	clear)
        # Prepare build. THIS WILL REMOVE ALL YOUR EXISTING DOCKER CONTAINERS AND IMAGES!
        docker stop $(docker ps -a -q)
        docker system prune -af
        docker rm $(docker ps -a -q)
        docker rmi $(docker images -q)
		;;

	slim-core)
        ####################################### SLIM PHP CORE IMAGE #########################################
        docker build --squash -t misaon/base-php-fpm:core -f ./base-php-fpm/Dockerfile ./base-php-fpm
        docker push misaon/base-php-fpm:core
		;;

	slim-base)
        ######################################## SLIM PHP BASE IMAGES #########################################
        ## PHP 8.0-dev base
        #docker build --squash -t misaon/base-php-fpm:8.0 -f ./base-php-fpm/8.0-dev/Dockerfile ./base-php-fpm/8.0-dev
        #docker push misaon/base-php-fpm:8.0

        # PHP 7.4-dev base
        docker build --squash -t misaon/base-php-fpm:7.4 -f ./base-php-fpm/7.4/Dockerfile ./base-php-fpm/7.4
        docker push misaon/base-php-fpm:7.4

        # PHP 7.3 base
        docker build --squash -t misaon/base-php-fpm:7.3 -f ./base-php-fpm/7.3/Dockerfile ./base-php-fpm/7.3
        docker push misaon/base-php-fpm:7.3

        # PHP 7.2 base
        docker build --squash -t misaon/base-php-fpm:7.2 -f ./base-php-fpm/7.2/Dockerfile ./base-php-fpm/7.2
        docker push misaon/base-php-fpm:7.2

        # PHP 7.1 base
        docker build --squash -t misaon/base-php-fpm:7.1 -f ./base-php-fpm/7.1/Dockerfile ./base-php-fpm/7.1
        docker push misaon/base-php-fpm:7.1
		;;

	slim-image)
        ###################################### SLIM PHP IMAGES ########################################
        # PHP 8.0 (dev)
        #buildTestAndPush "misaon/nginx-php:8.0-slim" "--build-arg BASE_IMAGE=misaon/base-php-fpm --build-arg BASE_TAG=8.0"

        # PHP 7.4 (dev)
        buildTestAndPush "misaon/nginx-php:7.4-slim" "--build-arg BASE_IMAGE=misaon/base-php-fpm --build-arg BASE_TAG=7.4"

        # PHP 7.3
        buildTestAndPush "misaon/nginx-php:7.3-slim" "--build-arg BASE_IMAGE=misaon/base-php-fpm --build-arg BASE_TAG=7.3"

        # PHP 7.2
        buildTestAndPush "misaon/nginx-php:7.2-slim" "--build-arg BASE_IMAGE=misaon/base-php-fpm --build-arg BASE_TAG=7.2"

        # PHP 7.1
        buildTestAndPush "misaon/nginx-php:7.1-slim" "--build-arg BASE_IMAGE=misaon/base-php-fpm --build-arg BASE_TAG=7.1"
		;;

	official-image)
        ######################################## OFFICIAL PHP IMAGES #########################################
        # PHP 7.3
        buildTestAndPush "misaon/nginx-php:7.3"

        # PHP 7.2
        buildTestAndPush "misaon/nginx-php:7.2" "--build-arg BASE_TAG=7.2-fpm-alpine3.9"

        # PHP 7.1
        buildTestAndPush "misaon/nginx-php:7.1" "--build-arg BASE_TAG=7.1-fpm-alpine3.8"

        # PHP 7.0
        buildTestAndPush "misaon/nginx-php:7.0" "--build-arg BASE_TAG=7.0-fpm-alpine"

        # PHP 5.6
        buildTestAndPush "misaon/nginx-php:5.6" "--build-arg BASE_TAG=5.6-fpm-alpine --build-arg PECL_MEMCACHED_VERSION=2.2.0"

        ### PHP 5.5
        ### This image cant be build because libzip-dev library is not available in this Alpine Linux version.
        ### If you like to build PHP 5.5, you must remove zip extension (docker-php-ext-install => zip and libzib-dev library).
        ;;

	*)
		usage
		exit 1
		;;
esac
