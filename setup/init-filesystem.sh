#!/bin/bash

set -e
DIR=$(cd "$(dirname "$0")"; pwd)

user=$1
if [[ -z "$user" ]]; then
    echo "Specify the user to own the data files as UID:GID"
    exit 1
fi

project=jacs
datadir=/data
db_dir=$datadir/db
mongo_data_dir=$db_dir/mongo/$project
mysql_data_dir=$db_dir/mysql/$project
rabbitmq_data_dir=$db_dir/rabbitmq/$project
config_dir=/opt/config_test

if [[ ! -e $config_dir ]]; then
    echo "Before running this script, create your config directory ($config_dir) and ensure you have write privileges to it."
    exit 1
fi

if [[ ! -e $db_dir ]]; then
    echo "Before running this script, create your data directory ($db_dir) and ensure you have write privileges to it."
    exit 1
fi

if [[ ! -e $mongo_data_dir ]]; then
    echo "Initializing MongoDB data directories"
    mkdir -p $mongo_data_dir/replica{1..3}
    openssl rand -base64 741 > mongodb-keyfile
    chmod 700 mongodb-keyfile
    echo $mongo_data_dir/replica{1..3} | xargs -n 1 cp mongodb-keyfile
    rm mongodb-keyfile
    sudo chown -R $user $mongo_data_dir
fi

if [[ ! -e $mysql_data_dir ]]; then
    echo "Initializing MySQL data directory"
    mkdir -p $mysql_data_dir
    sudo chown -R $user $mysql_data_dir
fi

if [[ ! -e $config_dir/mysql ]]; then
    echo "Deploying MySQL configuration"
    mkdir -p $config_dir/mysql/$project
    cp -R $DIR/mysql/conf $config_dir/mysql/$project
    cp -R $DIR/mysql/sql $config_dir/mysql/$project
fi

if [[ ! -e $rabbitmq_data_dir ]]; then
    echo "Initializing RabbitMQ data directory"
    mkdir -p $rabbitmq_data_dir
    sudo chown -R $user $rabbitmq_data_dir
fi

if [[ ! -e $config_dir/jwt_secret ]]; then
    echo "Generating new JWT Secret"
    openssl rand -base64 741 > $config_dir/jwt_secret
fi

if [[ ! -e $config_dir/certs ]]; then
    echo "Generating TLS Certificates"
    mkdir -p $config_dir/certs
    sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout $config_dir/certs/cert.key -out $config_dir/certs/cert.crt -config $DIR/selfsigned.conf
fi

if [[ ! -e $config_dir/jacs-async ]]; then
    echo "Initializing Async Services Config at $config_dir/jacs-async"
    mkdir -p $config_dir/jacs-async
    cp $DIR/jacs/* $config_dir/jacs-async/
fi

if [[ ! -e $config_dir/jacs-sync ]]; then
    echo "Initializing Sync Services Config at $config_dir/jacs-sync"
    mkdir -p $config_dir/jacs-sync
    cp $DIR/jacs/* $config_dir/jacs-sync/
fi

if [[ ! -e $config_dir/jade ]]; then
    echo "Initializing Jade Config at $config_dir/jade"
    mkdir -p $config_dir/jade
    cp $DIR/jade/* $config_dir/jade/
fi

