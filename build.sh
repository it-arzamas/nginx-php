#!/bin/bash


# Prevent continue script after exit code 1.
set -e


# Function for build, test and push PHP images.
buildTestAndPush() {
    truncateImageName=${1/\//-}
    truncateImageName=${truncateImageName/:/-}

    # Build image.
    if [ -z "$2" ]
    then
        if ! docker build --squash -t "$1" .
        then
            echo "Docker image $1 build failed."
            exit 1
        fi
    else
        IFS=" " read -r -a dockerImageBuildArgs <<< "$2"
        if ! docker build --squash "${dockerImageBuildArgs[@]}" -t "$1" .
        then
            echo "Docker image $1 build failed."
            exit 1
        fi
    fi

    # Run generated image in test mode.
    docker run -d -p 80:80 -e "TEST_MODE=true" --name "$truncateImageName" "$1"

    # Wait until is docker image fully loaded.
    sleep 3

    # Run nightwatch tests.
    if yarn run docker-test
    then
        docker push "$1"
    else
        echo "Docker image $1 test failed."
        exit 1
    fi

    # Clean up.
    docker stop "$truncateImageName"
    docker rm "$truncateImageName"
    docker rmi "$1"
}


# Run this via ./build.sh <command>
case "$1" in
        # Prepare build.
        # THIS WILL REMOVE ALL YOUR EXISTING DOCKER CONTAINERS AND IMAGES!
    clear)
        if [ -n "$(docker ps -q)" ]
        then
            docker stop "$(docker ps -q)"
        fi
        docker system prune -af
        ;;

        # Generate slim core PHP image for all slim images.
    slim-core)
        docker build --squash -t misaon/base-php-fpm:core -f ./base-php-fpm/Dockerfile ./base-php-fpm
        docker push misaon/base-php-fpm:core
        ;;

        # Generate slim base PHP images.
    slim-base)
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

        # Generate slim PHP images (with extensions).
    slim-image)
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

        # Generate official PHP images.
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
        exit 1
        ;;
esac
