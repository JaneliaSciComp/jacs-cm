#!/bin/bash

if [[ -z "$CONFIG_DIR" || -z "$DATA_DIR" ]]; then
    echo "You must specify your file system parameters in the .env file"
    exit 1
fi

set -e
DIR=$(cd "$(dirname "$0")"; pwd)

project=jacs
datadir=$DATA_DIR
db_dir=$datadir/db
www_dir=$datadir/www
mongo_data_dir=$db_dir/mongo/$project
mysql_data_dir=$db_dir/mysql/$project
rabbitmq_data_dir=$db_dir/rabbitmq/$project
elasticsearch_data_dir=$db_dir/elasticsearch/$project
config_dir=$CONFIG_DIR

if [[ ! -w $config_dir ]]; then
    echo "Before running this script, create your config directory ($config_dir) and ensure you have write privileges to it."
    exit 1
fi

if [[ ! -w $db_dir ]]; then
    echo "Before running this script, create your data directory ($db_dir) and ensure you have write privileges to it."
    exit 1
fi

if [[ ! -w $www_dir ]]; then
    echo "Before running this script, create your data directory ($www_dir) and ensure you have write privileges to it."
    exit 1
fi

if [[ ! -e $data_dir/portainer ]]; then
    mkdir $data_dir/portainer
fi

if [[ ! -e $mongo_data_dir ]]; then
    echo "Initializing MongoDB data directories"
    mkdir -p $mongo_data_dir/replica{1..3}
    openssl rand -base64 741 > mongodb-keyfile
    chmod 700 mongodb-keyfile
    echo $mongo_data_dir/replica{1..3} | xargs -n 1 cp mongodb-keyfile
    rm mongodb-keyfile
fi

if [[ ! -e $mysql_data_dir ]]; then
    echo "Initializing MySQL data directory"
    mkdir -p $mysql_data_dir
fi

if [[ ! -e $config_dir/mysql ]]; then
    echo "Deploying MySQL configuration"
    mysql_config_dir=$config_dir/mysql
    mkdir -p $mysql_config_dir/$project
    cp -R $DIR/mysql/conf $mysql_config_dir/$project
    cp -R $DIR/mysql/sql $mysql_config_dir/$project
fi

if [[ ! -e $config_dir/ipp ]]; then
    echo "Deploying IPP configuration"
    cp -R $DIR/ipp $config_dir
fi


if [[ ! -e $rabbitmq_data_dir ]]; then
    echo "Initializing RabbitMQ data directory"
    mkdir -p $rabbitmq_data_dir
fi

if [[ ! -e $elasticsearch_data_dir ]]; then
    echo "Initializing ElasticSearch data directory"
    mkdir -p $elasticsearch_data_dir
fi

if [[ ! -e $config_dir/certs ]]; then
    echo "Generating TLS Certificates"
    cert_dir=$config_dir/certs
    sudo mkdir -p $cert_dir
    sudo chmod 750 $cert_dir
    sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout $cert_dir/cert.key -out $cert_dir/cert.crt -config $DIR/certs/selfsigned.conf
fi

if [[ ! -e $config_dir/jacs-async ]]; then
    jacs_async_dir=$config_dir/jacs-async
    echo "Initializing Async Services Config at $jacs_async_dir"
    mkdir -p $jacs_async_dir
    cp $DIR/jacs/* $jacs_async_dir
fi

if [[ ! -e $config_dir/jacs-sync ]]; then
    jacs_sync_dir=$config_dir/jacs-sync
    echo "Initializing Sync Services Config at $jacs_sync_dir"
    mkdir -p $jacs_sync_dir
    cp $DIR/jacs/* $jacs_sync_dir
fi

if [[ ! -e $config_dir/jade ]]; then
    jade_dir=$config_dir/jade
    echo "Initializing Jade Config at $jade_dir"
    mkdir -p $jade_dir
    cp $DIR/jade/* $jade_dir
fi

if [[ ! -e $www_dir ]]; then
    mkdir -p $www_dir/updates
    mkdir -p $www_dir/workstation
fi

