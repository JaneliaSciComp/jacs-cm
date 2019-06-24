#!/bin/bash
#
# Management script for JACS containers
#

# Exit on error
set -e

# Directory containing this script
DIR=$(cd "$(dirname "$0")"; pwd)

# Constants
CONTAINER_DIRNAME=containers
DEPLOYMENTS_DIRNAME=deployments
CONTAINER_DIR="$DIR/$CONTAINER_DIRNAME"
SLEEP_TIME=6

# Container versioning (exported so that they're available for use in docker compose files)
export API_GATEWAY_VERSION=`cat $CONTAINER_DIR/api-gateway/VERSION`
export BUILDER_VERSION=`cat $CONTAINER_DIR/builder/VERSION`
export JACS_INIT_VERSION=`cat $CONTAINER_DIR/jacs-init/VERSION`
export JACS_COMPUTE_VERSION=`cat $CONTAINER_DIR/jacs-compute/VERSION`
export JACS_DASHBOARD_VERSION=`cat $CONTAINER_DIR/jacs-dashboard/VERSION`
export JACS_STORAGE_VERSION=`cat $CONTAINER_DIR/jacs-storage/VERSION`
export JACS_MESSAGING_VERSION=`cat $CONTAINER_DIR/jacs-messaging/VERSION`
export IPP_VERSION=`cat $CONTAINER_DIR/ipp/VERSION`
export SOLR_SEARCH_VERSION=`cat $CONTAINER_DIR/solr-search/VERSION`
export WORKSTATION_VERSION=`cat $CONTAINER_DIR/workstation-site/VERSION`

# Environment file
ENV_CONFIG=${ENV_CONFIG:-.env.config}
if [[ ! -f $DIR/$ENV_CONFIG ]]; then
    echo "You need to configure your $ENV_CONFIG file before using this script. Get started by copying the template:"
    echo "  cp .env.template $ENV_CONFIG"
    exit 1
fi

# Start with uninterpolated environment
. $DIR/$ENV_CONFIG

if [[ "$@" != "build builder" ]]; then

    # Generate environment
    echo "Generating .env from .env.config"
    echo "##################################################################################" > $DIR/.env
    echo "# This file was automatically generated from $ENV_CONFIG. Edit that instead!" >> $DIR/.env
    echo "##################################################################################" >> $DIR/.env
    echo "" >> $DIR/.env
    $DOCKER run --rm -v $DIR/$ENV_CONFIG:/env $NAMESPACE/builder:$BUILDER_VERSION /bin/bash -c "/usr/local/bin/multisub.sh /env"  >> $DIR/.env

    # Parse environment
    echo "Parsing .env"
    . $DIR/.env
fi

if [[ -z "$DEPLOYMENT" ]]; then
    echo "Your $ENV_CONFIG file must define a DEPLOYMENT to use"
fi
DEPLOYMENT_DIR="$DIR/$DEPLOYMENTS_DIRNAME/$DEPLOYMENT"
echo "Using deployment $DEPLOYMENT defined by $DEPLOYMENT_DIR"

# More variables
CONTAINER_PREFIX="$NAMESPACE/"
STACK_NAME=${COMPOSE_PROJECT_NAME}
NETWORK_NAME="${COMPOSE_PROJECT_NAME}_jacs-net"
MONGO_URL="${MONGODB_SERVER}/jacs?replicaSet=rsJacs&authSource=admin"

#
# Collect YAML files to compose together for the given tier and deployment method
#
function getyml() {

    local _tier="$1"
    local _dbonly="$2"
    local _swarm="$3"
    local _result_var="$4"

    YML=""

    if [[ -e "$DEPLOYMENT_DIR/docker-compose-db.yml" ]]; then
        YML="$YML -f $DEPLOYMENT_DIR/docker-compose-db.yml"
    fi

    if [ -n "${_tier}" ]; then
        if [[ -e "$DEPLOYMENT_DIR/docker-compose.${_tier}-db.yml" ]]; then
            YML="$YML -f $DEPLOYMENT_DIR/docker-compose.${_tier}-db.yml"
        fi
    fi

    if [[ "$_swarm" == "swarm" ]]; then
        YML="$YML -f $DEPLOYMENT_DIR/docker-swarm-db.yml"
    fi

    if [[ "$_dbonly" != "dbonly" ]]; then
        if [[ -e "$DEPLOYMENT_DIR/docker-compose-app.yml" ]]; then
            YML="$YML -f $DEPLOYMENT_DIR/docker-compose-app.yml"
        fi
        if [ -n "${_tier}" ]; then
            if [[ -e "$DEPLOYMENT_DIR/docker-compose.${_tier}-app.yml" ]]; then
                YML="$YML -f $DEPLOYMENT_DIR/docker-compose.${_tier}-app.yml"
            fi
            if [[ -e "$DEPLOYMENT_DIR/docker-compose.${_tier}.yml" ]]; then
                YML="$YML -f $DEPLOYMENT_DIR/docker-compose.${_tier}.yml"
            fi
        fi
        if [[ "$_swarm" == "swarm" ]]; then
            YML="$YML -f $DEPLOYMENT_DIR/docker-swarm-app.yml"

            if [ -n "${_tier}" ]; then
                if [[ -e "$DEPLOYMENT_DIR/docker-swarm.${_tier}-app.yml" ]]; then
                    YML="$YML -f $DEPLOYMENT_DIR/docker-swarm.${_tier}-app.yml"
                fi
                if [[ -e "$DEPLOYMENT_DIR/docker-swarm.${_tier}.yml" ]]; then
                    YML="$YML -f $DEPLOYMENT_DIR/docker-swarm.${_tier}.yml"
                fi
            fi

        fi
    fi

    eval $_result_var="'$YML'"
}

#
# Takes the container identifier, which might be "builder" or "./containers/builder" or "builder/" 
# and returns just the container name (e.g. "builder")
#
function getcontainer {
    local _name="$1"
    local _result_var="$2"
    NAME=${_name/$CONTAINER_DIRNAME\/}
    NAME=${NAME%/}
    NAME=${NAME#./}
    eval $_result_var="'$NAME'"
}

function getversion {
    local _name="$1"
    local _result_var="$2"
    CDIR="$CONTAINER_DIR/$_name"
    if [[ -e $CDIR/VERSION ]]; then
        VERSION=`cat $CDIR/VERSION`
        eval $_result_var="'$VERSION'"
    else
        echo "No $CDIR/VERSION found"
    fi
}

#
# Builds and tags the given container.
#
function build {
    local _name="$1"
    getcontainer $_name "NAME"
    getversion $NAME "VERSION"
    CDIR="$CONTAINER_DIR/$NAME"
    if [[ ! -z $VERSION ]]; then
        CNAME=${CONTAINER_PREFIX}${NAME}
        VNAME=$CNAME:${VERSION}
        LNAME=$CNAME:latest
        APP_TAG=$VERSION
        if [[ -e $CDIR/APP_TAG ]]; then
            APP_TAG=$(cat $CDIR/APP_TAG)
        fi
        BUILD_ARGS=""
        BUILD_ARGS="$BUILD_ARGS --build-arg APP_TAG=$APP_TAG"
        BUILD_ARGS="$BUILD_ARGS --build-arg API_GATEWAY_EXPOSED_HOST=$API_GATEWAY_EXPOSED_HOST"

        echo "---------------------------------------------------------------------------------"
        echo " Building image for $NAME"
        echo "---------------------------------------------------------------------------------"
        set -x
        $SUDO $DOCKER build --no-cache $BUILD_ARGS --label "version=$APP_TAG" -t $VNAME -t $LNAME $CDIR
        set +x
    fi

}


if [[ -z "$DOCKER_USER" ]]; then
    if [[ -z "$UNAME" || -z "$GNAME" ]]; then
        echo "Your .env file needs to either define the UNAME and GNAME variables, or the DOCKER_USER variable."
        exit 1
    fi
    MYUID=$(id -u $UNAME)
    if [[ `uname` == "Darwin" ]]; then
        MYGID=`dscl . -read /Groups/$GNAME | awk '($1 == "PrimaryGroupID:") { print $2 }'`
    else
        MYGID=`cut -d: -f3 < <(getent group $GNAME)`
    fi
    DOCKER_USER=$MYUID:$MYGID
else
    if [[ -z $MYUID || -z $MYGID ]]; then
        echo "Your .env file needs to either define the MYUID and MYGID variables, if you define the DOCKER_USER variable."
    fi
fi

if [[ "$1" == "build-all" ]]; then
    build "builder"
    for dir in ./containers/*
    do
        if [[ "$dir" != "builder" ]]; then
            build "$dir"
        fi
    done
    exit 0
fi

if [[ "$1" == "restart" ]]; then
    serviceName=$2
    if [[ -z "$serviceName" ]]; then
        echo "Specify a service name to restart"
    else
        set -x
        $SUDO $DOCKER service update --force $serviceName
        set +x
    fi
    exit 0
fi

if [[ "$1" == "debug" || "$1" == "status" ]]; then
    serviceName=$2
    if [[ -z "$serviceName" ]]; then
        set -x
        $SUDO $DOCKER service ls -f "name=$STACK_NAME"
        set +x
    else
        set -x
        $SUDO $DOCKER service ps --no-trunc $serviceName
        $SUDO $DOCKER service logs $serviceName
        set +x
    fi
    exit 0
fi

if [[ "$1" == "init-filesystems" ]]; then
    echo "Initializing swarm file systems..."
    YML="-f $DEPLOYMENT_DIR/swarm-init.yml"
    set -x
    DOCKER_USER="$DOCKER_USER" $DOCKER_COMPOSE $YML config > .tmp.swarm.yml
    $SUDO $DOCKER stack deploy --prune -c .tmp.swarm.yml $STACK_NAME && sleep 10
    $SUDO $DOCKER service logs --no-task-ids --no-trunc ${STACK_NAME}_jacs-init
    $SUDO $DOCKER service ps --no-trunc ${STACK_NAME}_jacs-init
    set +x
    echo "Filesystem initializing is running. When it's finished, all the tasks above should be in Shutdown state."
    echo "To clean up, run this command: docker service rm ${STACK_NAME}_jacs-init"
    exit 0
fi

if [[ "$1" == "init-local-filesystem" ]]; then
    echo "Initializing local file system..."
    set -x
    $SUDO $DOCKER run --rm --env-file .env -v ${REDUNDANT_STORAGE}:${REDUNDANT_STORAGE} -v ${NON_REDUNDANT_STORAGE}:${NON_REDUNDANT_STORAGE} -u $DOCKER_USER ${CONTAINER_PREFIX}jacs-init:${JACS_INIT_VERSION} /app/filesystem/run.sh
    set +x
    echo ""
    echo "The local filesystem is initialized. You should now edit the template files in $CONFIG_DIR to match your deployment environment."
    echo ""
    exit 0
fi

if [[ "$1" == "init-databases" ]]; then
    echo "Initializing databases..."
    set -x
    $SUDO $DOCKER run --rm --env-file .env -u $DOCKER_USER --network ${NETWORK_NAME} ${CONTAINER_PREFIX}jacs-init:${JACS_INIT_VERSION} /app/databases/run.sh
    set +x
    echo ""
    echo "Databases have been initialized."
    echo ""
    exit 0
fi

if [[ "$1" == "mongo" ]]; then
    echo "Opening MongoDB shell..."
    set -x
    $SUDO $DOCKER run -it -u $DOCKER_USER --network ${NETWORK_NAME} mongo:3.6 /usr/bin/mongo "mongodb://${MONGODB_APP_USERNAME}:${MONGODB_APP_PASSWORD}@${MONGO_URL}"
    set +x
    exit 0
fi

if [[ "$1" == "mysql" ]]; then
    echo "Opening MySQL shell..."
    set -x
    $SUDO $DOCKER run -it -u $DOCKER_USER --network ${NETWORK_NAME} mysql:5.6.42 /usr/bin/mysql -u ${MYSQL_JACS_USER} -p${MYSQL_JACS_PASSWORD} -h mysql ${MYSQL_DATABASE}
    set +x
    exit 0
fi

if [[ "$1" == "dbMaintenance" ]]; then
    echo "Perform DB maintenance..."
    shift
    if [[ $# == 0 ]]; then
        echo "$0 dbMaintenance <username> [-refreshIndexes] [-refreshPermissions]"
    exit 1
    fi
    userParam=username:"$1"
    shift

    service_args=()

    while [[ $# > 0 ]]; do
    key="$1"
    if [ "$key" == "" ] ; then
        break
    fi
    shift # past the key
    case $key in
        -refreshIndexes)
        service_args+=(\"-refreshIndexes\")
        ;;
        -refreshPermissions)
        service_args+=(\"-refreshPermissions\")
        ;;
        -h|--help)
        echo "$0 dbMaintenance <username> [-refreshIndexes] [-refreshPermissions]"
        exit 0
        ;;
        *)
        # invalid arg
        echo "$0 dbMaintenance <username> [-refreshIndexes] [-refreshPermissions]"
        exit 1
        ;;
    esac
    done

    if [[ ${#service_args[@]} == 0 ]]; then
        echo "$0 dbMaintenance <username> [-refreshIndexes] [-refreshPermissions]"
        exit 1
    fi

    service_json_args=$(printf ",%s" "${service_args[@]}")
    service_json_args="{\"args\": [${service_json_args:1}]}"

    set -x
    $DOCKER run --env-file .env -u $DOCKER_USER --network ${NETWORK_NAME} ${CONTAINER_PREFIX}jacs-async curl http://jacs-async:8080/api/rest-v2/async-services/dbMaintenance -H $userParam -H 'Accept: application/json' -H 'Content-Type: application/json' -d "${service_json_args}"
    set +x

    exit 0
fi

if [[ "$1" == "rebuildSolrIndex" ]]; then
    echo "Rebuilding SOLR index ..."
    shift

    set -x
    $DOCKER run --env-file .env -u $DOCKER_USER --network ${NETWORK_NAME} ${CONTAINER_PREFIX}jacs-sync curl -X PUT http://jacs-sync:8080/api/rest-v2/data/searchIndex?clearIndex=true -H "Authorization: APIKEY $JACS_API_KEY"
    set +x

    exit 0
fi

if [[ "$1" == "backup" ]]; then

    if [[ "$2" == "mongo" ]]; then

        FILENAME=mongo-$(date +%Y%m%d%H%M%S).archive
        MONGO_BACKUPS_DIR=$BACKUPS_DIR/mongo
        echo "Dumping Mongo backup to $MONGO_BACKUPS_DIR/$FILENAME"
        set -x
        $DOCKER run --rm -i -v $MONGO_BACKUPS_DIR:/backup -u $DOCKER_USER --network ${NETWORK_NAME} mongo:3.6 /usr/bin/mongodump --uri "mongodb://${MONGODB_APP_USERNAME}:${MONGODB_APP_PASSWORD}@${MONGO_URL}&readPreference=secondary" --archive=/backup/$FILENAME
        set +x
        exit 0

    elif [[ "$2" == "mysql" ]]; then

        FILENAME=flyportal-$(date +%Y%m%d%H%M%S).sql.gz
        MYSQL_BACKUPS_DIR=$BACKUPS_DIR/mysql
        echo "Dumping Mysql backup to $MYSQL_BACKUPS_DIR/$FILENAME"
        set -x
        $DOCKER run --rm -i -v $MYSQL_BACKUPS_DIR:/backup -u $DOCKER_USER --network ${NETWORK_NAME} mysql:5.6.42 bash -c "/usr/bin/mysqldump -u ${MYSQL_JACS_USER} -p${MYSQL_JACS_PASSWORD} -h mysql --all-databases | gzip >/backup/$FILENAME"
        set +x
        exit 0

    else

        echo "Valid choices for backups are mongo and mysql."
        exit 1

    fi
fi

if [[ "$1" == "login" ]]; then
    read -p "Username: " JACS_USERNAME
    read -s -p "Password: " JACS_PASSWORD
    echo
    export TOKEN=$(sudo docker run -it --rm --env-file .env $NAMESPACE/builder:latest /bin/bash -c "curl -sk --request POST --url https://${API_GATEWAY_EXPOSED_HOST}/SCSW/AuthenticationService/v1/authenticate --header \"Content-Type: application/json\" --data \"{\\\"username\\\":\\\"${JACS_USERNAME}\\\",\\\"password\\\":\\\"${JACS_PASSWORD}\\\"}\" | jq -r .token")
    echo "Token generated. Export it to your environment like this:"
    echo "export TOKEN=$TOKEN"
    exit 0
fi

if [[ "$#" -lt 2 ]]; then
    echo
    echo "This script simplifies deployment and management of the JACS system. Usage details:"
    echo
    echo "Container Management: [build|run|shell|push] [tool1] [tool2] .. [tooln]"
    echo "       You can combine multiple commands with a plus sign, e.g. build+push"
    echo
    echo "Installation: "
    echo "  init-local-filesystem - Initialize the local filesystem on the current host"
    echo "  init-filesystems - Initalize all filesystems in the Swarm"
    echo "  init-databases - Initialize the databases"
    echo
    echo "Swarm Deployment: [start|stop|status] [environment]"
    echo
    echo "Compose Deployment: compose [up|down|ps|top] [environment]"
    echo
    echo "Service Management:"
    echo "  status - Print the status of all services"
    echo "  status [service] - Print the status of the specified service"
    echo "  restart [service] - Fetch the latest container for the service and redeploy it"
    echo "  mongo - Open shell into the Mongo database"
    echo "  mysql - Open shell into the MySQL database"
    echo "  dbMaintenance - Ensure that all databases indexes and denormalizations are up-to-date"
    echo "  rebuildSolrIndex - Rebuild the SOLR index from scratch"
    echo "  backup [mongo|mysql] - Generate a database backup into $BACKUPS_DIR"
    echo "  login - Log into the system and generate a JWS token"
    echo
    exit 1
fi

COMMANDS=$1
CMDARR=(${COMMANDS//+/ })
shift 1 # remove command parameter from args

for COMMAND in "${CMDARR[@]}"
do
    #echo "Executing $COMMAND command on these targets: $@"

    if [[ "$COMMAND" == "build" ]]; then

        echo "Will build these images: $@"

        for NAME in "$@"
        do
            build $NAME
        done

    elif [[ "$COMMAND" == "run" ]]; then
        getcontainer $1 "NAME"
        getversion $NAME "VERSION"
        CDIR="$CONTAINER_DIR/$NAME"
        if [[ ! -z $VERSION ]]; then
            CNAME=${CONTAINER_PREFIX}${NAME}
            VNAME=$CNAME:${VERSION}
            set -x
            $SUDO $DOCKER run -it -u $DOCKER_USER --rm $VNAME
            set +x
        fi

    elif [[ "$COMMAND" == "lint" ]]; then

        echo "Will lint these images: $@"

        for NAME in "$@"
        do
            getcontainer $NAME "NAME"
            CDIR="$CONTAINER_DIR/$NAME"

            echo "---------------------------------------------------------------------------------"
            echo "Linting $NAME"
            # hadolint exits with an error code if there are linting issues, but we want to keep going
            set +e
            $SUDO $DOCKER run --rm -i hadolint/hadolint < $CDIR/Dockerfile
            set -e
        done

    elif [[ "$COMMAND" == "shell" ]]; then

        getcontainer $1 "NAME"
        getversion $NAME "VERSION"
        CDIR="$CONTAINER_DIR/$NAME"
        if [[ ! -z $VERSION ]]; then
            CNAME=${CONTAINER_PREFIX}${NAME}
            VNAME=$CNAME:${VERSION}
            set -x
            $SUDO $DOCKER run -it $VNAME /bin/bash
            set +x
        fi

    elif [[ "$COMMAND" == "push" ]]; then

        echo "Will push $@ to $CONTAINER_PREFIX"

        for NAME in "$@"
        do
            # TODO: in the future, these images will be externally configured, and these conditionals can be removed
            if [[ "$NAME" == "jacs-dashboard" ]]; then
                echo "Cannot push locally-configured image $NAME"
            else
                getcontainer $NAME "NAME"
                getversion $NAME "VERSION"
                CDIR="$CONTAINER_DIR/$NAME"
                if [[ ! -z $VERSION ]]; then
                    CNAME=${CONTAINER_PREFIX}${NAME}
                    VNAME=$CNAME:${VERSION}
                    LNAME=$CNAME:latest
                    echo "---------------------------------------------------------------------------------"
                    echo " Pushing image for $VNAME"
                    echo "---------------------------------------------------------------------------------"
                    set -x
                    $SUDO $DOCKER push $VNAME
                    set +x
                    echo "---------------------------------------------------------------------------------"
                    echo " Pushing image for $LNAME"
                    echo "---------------------------------------------------------------------------------"
                    set -x
                    $SUDO $DOCKER push $LNAME
                    set +x
                fi
            fi
        done

    elif [[ "$COMMAND" == "start" ]]; then

        TIER=$1
        shift 1 # remove tier

        if [[ $1 == "--dbonly" ]]; then
            getyml $TIER "dbonly" "swarm" "YML"
        else
            getyml $TIER "" "swarm" "YML"
        fi

        set -x
        DOCKER_USER="$DOCKER_USER" $DOCKER_COMPOSE $YML config > .tmp.swarm.yml
        $SUDO $DOCKER stack deploy --prune -c .tmp.swarm.yml $COMPOSE_PROJECT_NAME && sleep $SLEEP_TIME
        set +x

    elif [[ "$COMMAND" == "stop" ]]; then

        set -x
        $SUDO $DOCKER stack rm $COMPOSE_PROJECT_NAME && sleep $SLEEP_TIME
        set +x

    elif [[ "$COMMAND" == "compose" ]]; then

        shift 1 # remove command

        COMPOSE_COMMAND=$1
        shift 1 # remove compose command

        TIER=$1
        shift 1 # remove tier

        if [[ $1 == "--dbonly" ]]; then
            shift 1 # remove dbonly flag
            getyml $TIER "dbonly" "" "YML"
        else
            getyml $TIER "" "" "YML"
        fi

        OPTS="$@"
        echo "Bringing $COMMAND $TIER tier"
        set -x
        $SUDO DOCKER_USER="$DOCKER_USER" -E $DOCKER_COMPOSE $YML $COMPOSE_COMMAND $OPTS
        set +x

    else
        echo "Unrecognized command: $COMMAND"
        exit 1
    fi

done

