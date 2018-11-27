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
config_dir=/opt/config

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
    mysql_config_dir=$config_dir/mysql
    mkdir -p $mysql_config_dir/$project
    cp -R $DIR/mysql/conf $mysql_config_dir/$project
    cp -R $DIR/mysql/sql $mysql_config_dir/$project
    sudo chown -R $user $mysql_config_dir
fi

if [[ ! -e $rabbitmq_data_dir ]]; then
    echo "Initializing RabbitMQ data directory"
    mkdir -p $rabbitmq_data_dir
    sudo chown -R $user $rabbitmq_data_dir
fi

if [[ ! -e $config_dir/certs ]]; then
    echo "Generating TLS Certificates"
    cert_dir=$config_dir/certs
    mkdir -p $cert_dir
    sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout $certs_dir/cert.key -out $cert_dir/cert.crt -config $DIR/selfsigned.conf
    sudo chown root:root $cert_dir
    sudo chmod 750 $cert_dir
    sudo chmod 640 $cert_dir/*
fi

if [[ ! -e $config_dir/jacs-async ]]; then
    jacs_async_dir=$config_dir/jacs-async
    echo "Initializing Async Services Config at $jacs_async_dir"
    mkdir -p $jacs_async_dir
    cp $DIR/jacs/* $jacs_async_dir
    sudo chown -R $user $jacs_async_dir
fi

if [[ ! -e $config_dir/jacs-sync ]]; then
    jacs_sync_dir=$config_dir/jacs-sync
    echo "Initializing Sync Services Config at $jacs_sync_dir"
    mkdir -p $jacs_sync_dir
    cp $DIR/jacs/* $jacs_sync_dir
    sudo chown -R $user $jacs_sync_dir
fi

if [[ ! -e $config_dir/jade ]]; then
    jade_dir=$config_dir/jade
    echo "Initializing Jade Config at $jade_dir"
    mkdir -p $jade_dir
    cp $DIR/jade/* $jade_dir
    sudo chown -R $user $jade_dir
fi

