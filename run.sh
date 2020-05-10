#! /usr/bin/env bash

_LIVE_PORT=${LIVE_PORT:-8080}
_LIVE_PATH=${LIVE_PATH:-/tmp/live}
_DEV_PATH=${DEV_PATH:-$(pwd)}
_DEV_PORT=${DEV_PORT:-8081}


function runDB () {
    docker run --name osticket_mysql -d -e MYSQL_ROOT_PASSWORD=secret \
    -e MYSQL_USER=osticket -e MYSQL_PASSWORD=secret -e MYSQL_DATABASE=x mysql:5
    while true; do
        docker exec osticket_mysql mysql -u root -psecret -e "show databases"
        if [[ $? -eq 0 ]]; then
            break
        fi
        sleep 3
    done
}

function createDBs () {
    for db in osticket_live osticket_dev; do
        docker exec osticket_mysql mysql -u root -psecret -e "CREATE DATABASE IF NOT EXISTS ${db}; GRANT ALL PRIVILEGES ON ${db} . * TO 'osticket'"
    done;
}

function addLanguages () {
    docker run -v ${_LIVE_PATH}:/tmp/live --rm -it campbellsoftwaresolutions/osticket:1.9 cp -r /data/upload/include/i18n.dist /tmp/live/include/.
    docker run -v ${_DEV_PATH}:/tmp/dev --rm -it campbellsoftwaresolutions/osticket:1.9 cp -r /data/upload/include/i18n.dist /tmp/dev/include/.
}

function runOSTickets () {
    docker run --name osticket_live -v ${_LIVE_PATH}:/data/upload -e MYSQL_DATABASE="osticket_live" -e MYSQL_PASSWORD="secret" -d --link osticket_mysql:mysql -p ${_LIVE_PORT}:80 campbellsoftwaresolutions/osticket:1.9
    docker run --name osticket_dev -v ${_DEV_PATH}:/data/upload -e MYSQL_DATABASE="osticket_dev" -e MYSQL_PASSWORD="secret" -d --link osticket_mysql:mysql -p ${_DEV_PORT}:80 campbellsoftwaresolutions/osticket:1.9
    echo "running os-ticket in docker"
    echo "live running at http://localhost:${_LIVE_PORT} served from ${_LIVE_PATH}"
    echo "dev running at http://localhost:${_DEV_PORT} served from ${_DEV_PATH}"
}

function stop () {
    for container in osticket_mysql osticket_dev osticket_live; do
        docker stop $container;
    done;
}

function clean () {
    for container in osticket_mysql osticket_dev osticket_live; do
        docker rm $container;
    done;
}

case ${1} in
    "start")
        runDB
        createDBs
        addLanguages
        runOSTickets
    ;;
    "stop")
        stop
    ;;
    "clean")
        stop
        clean
    ;;
esac



