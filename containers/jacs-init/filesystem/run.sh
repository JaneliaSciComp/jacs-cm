#!/bin/bash
#
# Initializes CONFIG_DIR and DATA_DIR with default directory structures and configuration templates.
#

if [[ -z "$CONFIG_DIR" || -z "$DATA_DIR" || -z "$DB_DIR" || -z "$BACKUPS_DIR" ]]; then
    echo "You must specify your file system parameters in the .env file"
    exit 1
fi

set -e
DIR=$(cd "$(dirname "$0")"; pwd)

project=jacs
config_dir=$CONFIG_DIR
data_dir=$DATA_DIR
db_dir=$DB_DIR
backups_dir=$BACKUPS_DIR

if mkdir -p $config_dir; then
    echo "Verified $config_dir exists"
else
    echo "Before running this script, ensure your DOCKER_USER has write privilege to create your config directory ($config_dir)"
    exit 1
fi

if mkdir -p $db_dir; then
    echo "Verified $db_dir exists"
else
    echo "Before running this script, ensure your DOCKER_USER has write privilege to create your DB directory ($db_dir)"
    exit 1
fi

if mkdir -p $data_dir; then
    echo "Verified $data_dir exists"
else
    echo "Before running this script, ensure your DOCKER_USER has write privilege to create your config directory ($data_dir)"
    exit 1
fi

if mkdir -p $backups_dir; then
    echo "Verified $backups_dir exists"
else
    echo "Before running this script, ensure your DOCKER_USER has write privilege to create your backups directory ($backups_dir)"
    exit 1
fi

#
# Portainer Data Directory
#
portainer_data_dir=$db_dir/portainer
if [[ ! -e "$portainer_data_dir" ]]; then
    echo "Creating Portainer data directory: $portainer_data_dir"
    mkdir -p $portainer_data_dir
fi

#
# Mongo Data Directory
#
mongo_data_dir=$db_dir/mongo/$project
if [[ ! -e "$mongo_data_dir" ]]; then
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
mysql_data_dir=$db_dir/mysql/$project
if [[ ! -e "$mysql_data_dir" ]]; then
    echo "Initializing MySQL data directory"
    mkdir -p $mysql_data_dir
fi

#
# MySQL Database Configuration
#
mysql_config_dir=$config_dir/mysql
if [[ ! -e "$mysql_config_dir" ]]; then
    echo "Deploying MySQL configuration"
    mkdir -p $mysql_config_dir/$project
    cp -R $DIR/mysql/conf $mysql_config_dir/$project
    cp -R $DIR/mysql/sql $mysql_config_dir/$project
fi

#
# Image Processing Pipeline
#
if [[ ! -e "$config_dir/ipp" ]]; then
    echo "Deploying IPP configuration"
    cp -R $DIR/ipp $config_dir
fi

#
# RabbitMQ
#
rabbitmq_data_dir=$db_dir/rabbitmq/$project
if [[ ! -e "$rabbitmq_data_dir" ]]; then
    echo "Initializing RabbitMQ data directory"
    mkdir -p $rabbitmq_data_dir
fi

#
# Elasticsearch
#
elasticsearch_data_dir=$db_dir/elasticsearch/$project
if [[ ! -e "$elasticsearch_data_dir" ]]; then
    echo "Initializing ElasticSearch data directory"
    mkdir -p $elasticsearch_data_dir
fi

#
# TLS Certificates
#
cert_dir=$config_dir/certs
if [[ ! -e "$cert_dir" ]]; then
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
if [[ ! -e "$jacs_async_dir" ]]; then
    echo "Initializing Async Services Config at $jacs_async_dir"
    mkdir -p $jacs_async_dir
    cp $DIR/jacs/* $jacs_async_dir
fi

#
# JACS Sync Services
#
jacs_sync_dir=$config_dir/jacs-sync
if [[ ! -e "$jacs_sync_dir" ]]; then
    echo "Initializing Sync Services Config at $jacs_sync_dir"
    mkdir -p $jacs_sync_dir
    cp $DIR/jacs/* $jacs_sync_dir
fi

#
# JADE
#
jade_config_dir=$config_dir/jade
if [[ ! -e "$jade_config_dir" ]]; then
    echo "Initializing Jade Config at $jade_config_dir"
    mkdir -p $jade_config_dir
    cp $DIR/jade/* $jade_config_dir
fi
jade_data_dir=$data_dir/jacsstorage
if [[ ! -e "$jade_data_dir" ]]; then
    echo "Initializing Jade storage at $data_dir/jacsstorage"
    mkdir $data_dir/jacsstorage
fi


#
# API Gateway
#
apigateway_dir=$config_dir/api-gateway
if [[ ! -e "$apigateway_dir" ]]; then
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
# Database Backup Directories
#
if [[ ! -e "$MONGO_BACKUPS_DIR" ]]; then
    echo "Creating directory: $MONGO_BACKUPS_DIR"
    mkdir -p $MONGO_BACKUPS_DIR
fi
if [[ ! -e "$MYSQL_BACKUPS_DIR" ]]; then
    echo "Creating directory: $MYSQL_BACKUPS_DIR"
    mkdir -p $MYSQL_BACKUPS_DIR
fi
if [[ ! -e "$RABBITMQ_BACKUPS_DIR" ]]; then
    echo "Creating directory: $RABBITMQ_BACKUPS_DIR"
    mkdir -p $RABBITMQ_BACKUPS_DIR
fi

