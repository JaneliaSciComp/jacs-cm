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

function init_solr_core() {
    local solr_data_dir=$1
    local core_subdir=$2
    local core_name=$3

    local solr_config_dir=${solr_data_dir}

    if [[ ! -e "${solr_data_dir}/${core_subdir}" ]]; then
        echo "Initializing SOLR Index dir: ${solr_data_dir}/${core_subdir}"
        mkdir -p ${solr_data_dir}/${core_subdir}
    fi

    if [[ ! -e "${solr_config_dir}/${core_subdir}" ]]; then
        echo "Initializing SOLR ${core_subdir} config directory: ${solr_config_dir}/${core_subdir}"
        mkdir -p ${solr_config_dir}/${core_subdir}
    fi

    if [[ ! -e "${solr_config_dir}/${core_subdir}/conf" ]]; then
        cp -a $DIR/solr/conf ${solr_config_dir}/${core_subdir}
    fi

    if [[ ! -e "${solr_config_dir}/${core_subdir}/core.properties" ]]; then
        sed s/this_core_name/${core_name}/ $DIR/solr/core.properties > ${solr_config_dir}/${core_subdir}/core.properties
    fi

    echo "Verified SOLR ${core_subdir} config -> $solr_config_dir/${core_subdir}"
}

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
# Initialize Solr Config
#
solr_data_dir=$db_dir/solr
init_solr_core $solr_data_dir core0 FlyWorkstation
init_solr_core $solr_data_dir core1 FlyWorkstationBuild
cp $DIR/solr/solr.xml ${solr_data_dir}

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
# JACS Dashboard
#
jacs_dashboard_dir=$config_dir/jacs-dashboard
if [[ ! -e "$jacs_dashboard_dir" ]]; then
    echo "Initializing JACS Dashboard config directory: $jacs_dashboard_dir"
    mkdir -p $jacs_dashboard_dir
    sed s/%API%/$API_GATEWAY_EXPOSED_HOST/ $DIR/jacs-dashboard/conf.json > $jacs_dashboard_dir/conf.json
else
    echo "Verified JACS Dashboard config directory: $jacs_dashboard_dir"
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

# Messaging
#
messaging_config_dir=$config_dir/messaging
if [[ ! -e "$messaging_config_dir" ]]; then
    echo "Initializing jacs-messaging config directory: $messaging_config_dir"
    mkdir -p $messaging_config_dir
    cp $DIR/messaging/* $messaging_config_dir
else
    echo "Verified jacs-messaging config directory: $messaging_config_dir"
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

    API_GATEWAY_EXPOSED_HOST=$API_GATEWAY_EXPOSED_HOST \
    RABBITMQ_EXPOSED_HOST=$RABBITMQ_EXPOSED_HOST \
    RABBITMQ_USER=$RABBITMQ_USER \
    RABBITMQ_PASSWORD=$RABBITMQ_PASSWORD \
    MAIL_SERVER=$MAIL_SERVER \
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

messaging_backups_dir=$BACKUPS_DIR/messaging
if [[ ! -e "$messaging_backups_dir" ]]; then
    echo "Creating jacs-messaging backups directory: $messaging_backups_dir"
    mkdir -p $messaging_backups_dir
else
    echo "Verified jacs-messaging backups directory: $messaging_backups_dir"
fi

#
# ElasticSearch Indexes Directory
#
elasticsearch_data_dir=$DATA_DIR/elasticsearch
if [[ ! -e "${elasticsearch_data_dir}" ||
      ! -e "${elasticsearch_data_dir}/data" ||
      ! -e "${elasticsearch_data_dir}/master" ||
      ! -e "${elasticsearch_data_dir}/kibana" ]]; then
    echo "Initializing ElasticSearch indexes directory: ${elasticsearch_data_dir}"
    mkdir -p "${elasticsearch_data_dir}/data"
    mkdir -p "${elasticsearch_data_dir}/master"
    mkdir -p "${elasticsearch_data_dir}/kibana"
    chmod -R 2777 ${elasticsearch_data_dir}
else
    echo "Verified ElasticSearch indexes directory: $elasticsearch_data_dir"
fi

#
# Logstash config
#
logstash_dir=$config_dir/logstash
if [[ ! -e "$logstash_dir" ]]; then
    echo "Initializing logstash config directory: $logstash_dir"
    mkdir -p "${logstash_dir}"

    echo "Copy logstash configuration"
    cp -a $DIR/logstash/pipelines.yml "$logstash_dir"
    cp -a $DIR/logstash/pipeline "$logstash_dir"
else
    echo "Verified logstash config directory: $logstash_dir"
fi

#
# Kibana config
#
kibana_dir=$config_dir/kibana
if [[ ! -e "$kibana_dir" ]]; then
    echo "Initializing Kibana config directory: $kibana_dir"
    mkdir -p "${kibana_dir}"

    echo "Copy kibana configuration"
    cp -a $DIR/kibana/kibana.yml "$kibana_dir"
else
    echo "Verified kibana config directory: $kibana_dir"
fi

#
# Filebeat config
#
filebeat_dir=$config_dir/filebeat
if [[ ! -e "$filebeat_dir" ]]; then
    echo "Initializing filebeat config directory: $filebeat_dir"
    cp -a $DIR/filebeat $config_dir
else
    echo "Verified filebeat config directory: $filebeat_dir"
fi

filebeat_containers_dir=$config_dir/filebeat/docker/containers
if [[ ! -e "$filebeat_containers_dir" ]]; then
    echo "Initializing filebeat containers directory: $filebeat_containers_dir"
    mkdir -p $filebeat_containers_dir
else
    echo "Verified filebeat containers directory: $filebeat_containers_dir"
fi
