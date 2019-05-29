#!/bin/bash
#
# Initializes CONFIG_DIR, DATA_DIR, DB_DIR, and BACKUPS_DIR with default directory structures and configuration templates.
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
    echo "Verified CONFIG_DIR exists: $config_dir"
else
    echo "Before running this script, ensure your DOCKER_USER has write privilege to create your config directory ($config_dir)"
    exit 1
fi

if mkdir -p $db_dir; then
    echo "Verified DB_DIR exists: $db_dir"
else
    echo "Before running this script, ensure your DOCKER_USER has write privilege to create your DB directory ($db_dir)"
    exit 1
fi

if mkdir -p $data_dir; then
    echo "Verified DATA_DIR exists: $data_dir"
else
    echo "Before running this script, ensure your DOCKER_USER has write privilege to create your config directory ($data_dir)"
    exit 1
fi

if mkdir -p $backups_dir; then
    echo "Verified BACKUPS_DIR exists: $backups_dir"
else
    echo "Before running this script, ensure your DOCKER_USER has write privilege to create your backups directory ($backups_dir)"
    exit 1
fi

#
# Mongo Data Directory
#
mongo_data_dir=$db_dir/mongo/$project
if [[ ! -e "$mongo_data_dir" ]]; then
    echo "Initializing MongoDB data directories: $mongo_data_dir"
    mkdir -p $mongo_data_dir/replica{1..3}
    if [[ -z "$MONGODB_SECRET_KEY" ]]; then
        echo "Generating new keyfiles"
        openssl rand -base64 741 > /tmp/mongodb-keyfile
    else
        echo "$MONGODB_SECRET_KEY" > /tmp/mongodb-keyfile
    fi
    chmod 700 /tmp/mongodb-keyfile
    echo $mongo_data_dir/replica{1..3} | xargs -n 1 cp /tmp/mongodb-keyfile
    rm /tmp/mongodb-keyfile
else
    echo "Verified MongoDB data directories: $mongo_data_dir"
fi

#
# MySQL Data Directory
#
mysql_data_dir=$db_dir/mysql/$project
if [[ ! -e "$mysql_data_dir" ]]; then
    echo "Initializing MySQL data directory: $mysql_data_dir"
    mkdir -p $mysql_data_dir
else
    echo "Verified MySQL data directory: $mysql_data_dir"
fi

#
# MySQL Database Configuration
#
mysql_config_dir=$config_dir/mysql
if [[ ! -e "$mysql_config_dir" ]]; then
    echo "Deploying MySQL config directory: $mysql_config_dir"
    mkdir -p $mysql_config_dir/$project
    cp -R $DIR/mysql/conf $mysql_config_dir/$project
    cp -R $DIR/mysql/sql $mysql_config_dir/$project
else
    echo "Verified MySQL config directory: $mysql_config_dir"
fi

#
# SOLR Indexes Directory
#
solr_data_dir=$db_dir/solr
if [[ ! -e "$solr_data_dir" ]]; then
    echo "Initializing SOLR indexes directory: $solr_data_dir"
    mkdir -p $solr_data_dir
else
    echo "Verified SOLR indexes directory: $solr_data_dir"
fi

#
# RabbitMQ
#
rabbitmq_data_dir=$db_dir/rabbitmq/$project
if [[ ! -e "$rabbitmq_data_dir" ]]; then
    echo "Initializing RabbitMQ data directory: $rabbitmq_data_dir"
    mkdir -p $rabbitmq_data_dir
else
    echo "Verified RabbitMQ data directory: $rabbitmq_data_dir"
fi

#
# Elasticsearch
#
elasticsearch_data_dir=$db_dir/elasticsearch/$project
if [[ ! -e "$elasticsearch_data_dir" ]]; then
    echo "Initializing ElasticSearch data directory: $elasticsearch_data_dir"
    mkdir -p $elasticsearch_data_dir
else
    echo "Verified ElasticSearch data directory: $elasticsearch_data_dir"
fi

#
# TLS Certificates
#
cert_dir=$config_dir/certs
if [[ ! -e "$cert_dir" ]]; then
    echo "Initializing certificates directory: $cert_dir"
    mkdir -p $cert_dir
    chmod 750 $cert_dir
    echo "  Generating TLS certificate using subject: $CERT_SUBJ"
    openssl req -x509 -nodes -days 365 -new -newkey rsa:2048 -subj "$CERT_SUBJ" -keyout $cert_dir/cert.key -out $cert_dir/cert.crt
else
    echo "Verified certificates directory: $cert_dir"
fi

#
# JACS Async Services
#
jacs_async_dir=$config_dir/jacs-async
if [[ ! -e "$jacs_async_dir" ]]; then
    echo "Initializing JACS Async Services config directory: $jacs_async_dir"
    mkdir -p $jacs_async_dir
    cp $DIR/jacs/* $jacs_async_dir
else
    echo "Verified JACS Async Services config directory: $jacs_async_dir"
fi

#
# JACS Sync Services
#
jacs_sync_dir=$config_dir/jacs-sync
if [[ ! -e "$jacs_sync_dir" ]]; then
    echo "Initializing JACS Sync Services config directory: $jacs_sync_dir"
    mkdir -p $jacs_sync_dir
    cp $DIR/jacs/* $jacs_sync_dir
else
    echo "Verified JACS Sync Services config directory: $jacs_sync_dir"
fi

#
# JADE
#
jade_config_dir=$config_dir/jade
if [[ ! -e "$jade_config_dir" ]]; then
    echo "Initializing Jade config directory: $jade_config_dir"
    mkdir -p $jade_config_dir
    cp $DIR/jade/* $jade_config_dir
else
    echo "Verified Jade config directory: $jade_config_dir"
fi

jade_data_dir=$data_dir/jacsstorage
if [[ ! -e "$jade_data_dir" ]]; then
    echo "Initializing Jade storage: $jade_data_dir"
    mkdir -p $jade_data_dir
else
    echo "Verified Jade storage: $jade_data_dir"
fi

#
# Image Processing Pipeline
#
ipp_config_dir=$config_dir/ipp
if [[ ! -e "$ipp_config_dir" ]]; then
    echo "Initializing IPP config directory: $ipp_config_dir"
    mkdir -p $ipp_config_dir
    cp -R $DIR/ipp/* $ipp_config_dir
else
    echo "Verified IPP config directory: $ipp_config_dir"
fi

#
# API Gateway
#
apigateway_dir=$config_dir/api-gateway
if [[ ! -e "$apigateway_dir" ]]; then
    echo "Initializing API Gateway config directory: $apigateway_dir"
    mkdir -p $apigateway_dir

    if [[ -e $DIR/api-gateway/deployments/$DEPLOYMENT ]]; then
        echo "  Using gateway configuration for $DEPLOYMENT deployment"
        cp $DIR/api-gateway/deployments/$DEPLOYMENT/nginx.conf $apigateway_dir
    else
        echo "  Using default gateway configuration"
        cp $DIR/api-gateway/nginx.conf $apigateway_dir
    fi

    content_dir=$apigateway_dir/content
    mkdir -p $content_dir
    echo "  Created content directory: $content_dir"

    RABBITMQ_EXPOSED_HOST=$RABBITMQ_EXPOSED_HOST \
    MAIL_SERVER=$MAIL_SERVER \
    RABBITMQ_USER=$RABBITMQ_USER \
    RABBITMQ_PASSWORD=$RABBITMQ_PASSWORD \
    envsubst < $DIR/api-gateway/client/client.properties > $content_dir/client.properties
    echo "  Created client properties: $content_dir/client.properties"

else
    echo "Verified API Gateway config directory: $apigateway_dir"
fi

#
# Database Backup Directories
#
mongo_backups_dir=$BACKUPS_DIR/mongo
if [[ ! -e "$mongo_backups_dir" ]]; then
    echo "Creating Mongo backups directory: $mongo_backups_dir"
    mkdir -p $mongo_backups_dir
else
    echo "Verified Mongo backups directory: $mongo_backups_dir"
fi

mysql_backups_dir=$BACKUPS_DIR/mysql
if [[ ! -e "$mysql_backups_dir" ]]; then
    echo "Creating MySQL backups directory: $mysql_backups_dir"
    mkdir -p $mysql_backups_dir
else
    echo "Verified MySQL backups directory: $mysql_backups_dir"
fi

messaging_backups_dir=$BACKUPS_DIR/messaging
if [[ ! -e "$messaging_backups_dir" ]]; then
    echo "Creating jacs-messaging backups directory: $messaging_backups_dir"
    mkdir -p $messaging_backups_dir
else
    echo "Verified jacs-messaging backups directory: $messaging_backups_dir"
fi

