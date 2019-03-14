#!/bin/bash
#
# Initializes CONFIG_DIR and DATA_DIR with default directory structures and configuration templates.
#

if [[ -z "$CONFIG_DIR" || -z "$DATA_DIR" ]]; then
    echo "You must specify your file system parameters in the .env file"
    exit 1
fi

set -e
DIR=$(cd "$(dirname "$0")"; pwd)

project=jacs
data_dir=$DATA_DIR
db_dir=$data_dir/db
www_dir=$data_dir/www
mongo_data_dir=$db_dir/mongo/$project
mysql_data_dir=$db_dir/mysql/$project
rabbitmq_data_dir=$db_dir/rabbitmq/$project
elasticsearch_data_dir=$db_dir/elasticsearch/$project
config_dir=$CONFIG_DIR

if [[ ! -w $config_dir ]]; then
    echo "Before running this script, create your config directory ($config_dir) and ensure your DOCKER_USER has write privileges to it."
    exit 1
fi

if [[ ! -w $data_dir ]]; then
    echo "Before running this script, create your data directory ($data_dir) and ensure your DOCKER_USER has write privileges to it."
    exit 1
fi

#
# Database Directory
#
if [[ ! -e $db_dir ]]; then
    echo "Creating directory: $db_dir"
    mkdir $db_dir
fi

#
# Portainer Data Directory
#
if [[ ! -e $data_dir/portainer ]]; then
    echo "Creating directory: $data_dir/portainer"
    mkdir $data_dir/portainer
fi

#
# Mongo Data Directory
#
if [[ ! -e $mongo_data_dir ]]; then
    echo "Initializing MongoDB data directories"
    mkdir -p $mongo_data_dir/replica{1..3}
    openssl rand -base64 741 > /tmp/mongodb-keyfile
    chmod 700 /tmp/mongodb-keyfile
    echo $mongo_data_dir/replica{1..3} | xargs -n 1 cp /tmp/mongodb-keyfile
    rm /tmp/mongodb-keyfile
fi

#
# MySQL Data Directory
#
if [[ ! -e $mysql_data_dir ]]; then
    echo "Initializing MySQL data directory"
    mkdir -p $mysql_data_dir
fi

#
# MySQL Database Configuration
#
if [[ ! -e $config_dir/mysql ]]; then
    echo "Deploying MySQL configuration"
    mysql_config_dir=$config_dir/mysql
    mkdir -p $mysql_config_dir/$project
    cp -R $DIR/mysql/conf $mysql_config_dir/$project
    cp -R $DIR/mysql/sql $mysql_config_dir/$project
fi

#
# Image Processing Pipeline
#
if [[ ! -e $config_dir/ipp ]]; then
    echo "Deploying IPP configuration"
    cp -R $DIR/ipp $config_dir
fi

#
# RabbitMQ
#
if [[ ! -e $rabbitmq_data_dir ]]; then
    echo "Initializing RabbitMQ data directory"
    mkdir -p $rabbitmq_data_dir
fi

#
# Elasticsearch
#
if [[ ! -e $elasticsearch_data_dir ]]; then
    echo "Initializing ElasticSearch data directory"
    mkdir -p $elasticsearch_data_dir
fi

#
# TLS Certificates
#
cert_dir=$config_dir/certs
if [[ ! -e $cert_dir ]]; then
    echo "Initializing Certificates at $cert_dir"
    mkdir -p $cert_dir
    chmod 750 $cert_dir
    echo "  Generating TLS certificate using subject: $CERT_SUBJ"
    openssl req -x509 -nodes -days 365 -new -newkey rsa:2048 -subj "$CERT_SUBJ" -keyout $cert_dir/cert.key -out $cert_dir/cert.crt
fi

#
# JACS Async Services
#
jacs_async_dir=$config_dir/jacs-async
if [[ ! -e $jacs_async_dir ]]; then
    echo "Initializing Async Services Config at $jacs_async_dir"
    mkdir -p $jacs_async_dir
    cp $DIR/jacs/* $jacs_async_dir
fi

#
# JACS Sync Services
#
jacs_sync_dir=$config_dir/jacs-sync
if [[ ! -e $jacs_sync_dir ]]; then
    echo "Initializing Sync Services Config at $jacs_sync_dir"
    mkdir -p $jacs_sync_dir
    cp $DIR/jacs/* $jacs_sync_dir
fi

#
# JADE
#
jade_dir=$config_dir/jade
if [[ ! -e $jade_dir ]]; then
    echo "Initializing Jade Config at $jade_dir"
    mkdir -p $jade_dir
    cp $DIR/jade/* $jade_dir
    echo "Initializing Jade storage at $data_dir/jacsstorage"
    mkdir $data_dir/jacsstorage
fi

#
# API Gateway
#
apigateway_dir=$config_dir/api-gateway
if [[ ! -e $apigateway_dir ]]; then
    echo "Initializing API Gateway Config at $apigateway_dir"
    mkdir -p $apigateway_dir
    if [[ -e $DIR/api-gateway/deployments/$DEPLOYMENT ]]; then
        echo "  Using gateway configuration for $DEPLOYMENT deployment"
        cp -r $DIR/api-gateway/deployments/$DEPLOYMENT/* $apigateway_dir
    else
        echo "  Using default gateway configuration"
        cp -r $DIR/api-gateway/* $apigateway_dir
    fi
fi

#
# LDAP Auth Service
#
authservice_dir=$config_dir/auth-service
if [[ ! -e $authservice_dir ]]; then
    echo "Initializing LDAP Auth Service Config at $authservice_dir"
    mkdir -p $authservice_dir
    cp -r $DIR/auth-service/* $authservice_dir
fi

#
# Static Web Content
#
if [[ ! -e $www_dir ]]; then
    echo "Initializing WWW directory at $www_dir"
    mkdir -p $www_dir/updates
    mkdir -p $www_dir/workstation
fi

