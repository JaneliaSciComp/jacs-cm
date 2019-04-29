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
    $SUDO $DOCKER run --rm -v $DIR/$ENV_CONFIG:/env $NAMESPACE/builder:$BUILDER_VERSION /bin/bash -c "/usr/local/bin/multisub.sh /env"  >> $DIR/.env

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
NETWORK_NAME="${COMPOSE_PROJECT_NAME}_jacs-net"
MONGO_SERVER="mongo1:27017,mongo2:27017,mongo3:27017/jacs?replicaSet=rsJacs&authSource=admin"

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
        if [[ "$VERSION" == "\$WORKSTATION_BUILD_VERSION" ]]; then
            # Poor man's variable interpolation
            VERSION=$WORKSTATION_BUILD_VERSION
        fi
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
        APP_TAG=master
        if [[ "$NAME" == "workstation-site" ]]; then
            APP_TAG=$WORKSTATION_TAG
        elif [[ -e $CDIR/APP_TAG ]]; then
            APP_TAG=$(cat $CDIR/APP_TAG)
        fi
        BUILD_ARGS=""
        BUILD_ARGS="$BUILD_ARGS --build-arg APP_TAG=$APP_TAG"
        BUILD_ARGS="$BUILD_ARGS --build-arg API_GATEWAY_EXPOSED_HOST=$API_GATEWAY_EXPOSED_HOST"
        BUILD_ARGS="$BUILD_ARGS --build-arg RABBITMQ_EXPOSED_HOST=$RABBITMQ_EXPOSED_HOST"
        BUILD_ARGS="$BUILD_ARGS --build-arg RABBITMQ_USER=$RABBITMQ_USER"
        BUILD_ARGS="$BUILD_ARGS --build-arg RABBITMQ_PASSWORD=$RABBITMQ_PASSWORD"
        BUILD_ARGS="$BUILD_ARGS --build-arg WORKSTATION_BUILD_VERSION=$WORKSTATION_BUILD_VERSION"
        BUILD_ARGS="$BUILD_ARGS --build-arg KEYSTORE_PASSWORD=$KEYSTORE_PASSWORD"
        BUILD_ARGS="$BUILD_ARGS --build-arg MAIL_SERVER=$MAIL_SERVER"
        BUILD_ARGS="$BUILD_ARGS --build-arg CERT_PATH=$CONFIG_DIR/certs/cert.crt"

        echo "---------------------------------------------------------------------------------"
        echo " Building image for $NAME"
        echo " $SUDO $DOCKER build --no-cache $BUILD_ARGS -t $VNAME -t $LNAME $CDIR"
        echo "---------------------------------------------------------------------------------"
        $SUDO $DOCKER build --no-cache $BUILD_ARGS -t $VNAME -t $LNAME $CDIR
    fi

}


if [[ -z "$DOCKER_USER" ]]; then
    if [[ -z "$UNAME" || -z "$GNAME" ]]; then
        echo "Your .env file needs to either define the UNAME and GNAME variables, or the DOCKER_USER variable."
        exit 1
    fi
    MYUID=$(id -u $UNAME)
    MYGID=`cut -d: -f3 < <(getent group $GNAME)`
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


if [[ "$1" == "init-filesystems" ]]; then
    STACK_NAME=$COMPOSE_PROJECT_NAME
    echo "Initializing swarm file systems..."
    YML="-f $DEPLOYMENT_DIR/swarm-init.yml"
    echo "DOCKER_USER=\"$DOCKER_USER\" $DOCKER_COMPOSE $YML config > .tmp.swarm.yml"
    DOCKER_USER="$DOCKER_USER" $DOCKER_COMPOSE $YML config > .tmp.swarm.yml
    echo "$SUDO $DOCKER stack deploy -c .tmp.swarm.yml $STACK_NAME && sleep 10"
    $SUDO $DOCKER stack deploy -c .tmp.swarm.yml $STACK_NAME && sleep 10
    echo "$SUDO $DOCKER service logs --no-task-ids --no-trunc ${STACK_NAME}_jacs-init"
    $SUDO $DOCKER service logs --no-task-ids --no-trunc ${STACK_NAME}_jacs-init
    echo "Filesystem initializing is running. When it's finished, all these tasks should be in Shutdown state:"
    echo "$SUDO $DOCKER service ps ${STACK_NAME}_jacs-init"
    $SUDO $DOCKER service ps ${STACK_NAME}_jacs-init
    exit 0
fi

if [[ "$1" == "init-local-filesystem" ]]; then
    echo "Initializing local file system..."
    echo "$SUDO $DOCKER run --rm --env-file .env -v $CONFIG_DIR:$CONFIG_DIR -v $DB_DIR:$DB_DIR -v $DATA_DIR:$DATA_DIR -v $BACKUPS_DIR:$BACKUPS_DIR -u $DOCKER_USER ${CONTAINER_PREFIX}jacs-init:${JACS_INIT_VERSION} /app/filesystem/run.sh"
    $SUDO $DOCKER run --rm --env-file .env -v $CONFIG_DIR:$CONFIG_DIR -v $DB_DIR:$DB_DIR -v $DATA_DIR:$DATA_DIR -v $BACKUPS_DIR:$BACKUPS_DIR -u $DOCKER_USER ${CONTAINER_PREFIX}jacs-init:${JACS_INIT_VERSION} /app/filesystem/run.sh
    echo ""
    echo "The local filesystem is initialized. You should now edit the template files in $CONFIG_DIR to match your deployment environment."
    echo ""
    exit 0
fi

if [[ "$1" == "init-databases" ]]; then
    echo "Initializing databases..."
    echo "$SUDO $DOCKER run --rm --env-file .env -u $DOCKER_USER --network ${NETWORK_NAME} ${CONTAINER_PREFIX}jacs-init:${JACS_INIT_VERSION} /app/databases/run.sh"
    $SUDO $DOCKER run --rm --env-file .env -u $DOCKER_USER --network ${NETWORK_NAME} ${CONTAINER_PREFIX}jacs-init:${JACS_INIT_VERSION} /app/databases/run.sh
    echo ""
    echo "Databases have been initialized."
    echo ""
    exit 0
fi

if [[ "$1" == "mongo" ]]; then
    echo "Opening MongoDB shell..."
    echo "$SUDO $DOCKER run -it -u $DOCKER_USER --network ${NETWORK_NAME} mongo:3.6 /usr/bin/mongo \"mongodb://${MONGODB_APP_USERNAME}:****@${MONGO_SERVER}\""
    $SUDO $DOCKER run -it -u $DOCKER_USER --network ${NETWORK_NAME} mongo:3.6 /usr/bin/mongo "mongodb://${MONGODB_APP_USERNAME}:${MONGODB_APP_PASSWORD}@${MONGO_SERVER}"
    exit 0
fi

if [[ "$1" == "mysql" ]]; then
    echo "Opening MySQL shell..."
    echo "$SUDO $DOCKER run -it -u $DOCKER_USER --network ${NETWORK_NAME} mysql:5.6.42 /usr/bin/mysql -u ${MYSQL_JACS_USER} -p**** -h mysql ${MYSQL_DATABASE}"
    $SUDO $DOCKER run -it -u $DOCKER_USER --network ${NETWORK_NAME} mysql:5.6.42 /usr/bin/mysql -u ${MYSQL_JACS_USER} -p${MYSQL_ROOT_PASSWORD} -h mysql ${MYSQL_DATABASE}
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

    echo "$SUDO $DOCKER run --env-file .env -u $DOCKER_USER --network ${NETWORK_NAME} ${CONTAINER_PREFIX}jacs-async curl http://jacs-async:8080/api/rest-v2/async-services/dbMaintenance -H $userParam -H 'Accept: application/json' -H 'Content-Type: application/json' -d ${service_json_args}"
    $SUDO $DOCKER run --env-file .env -u $DOCKER_USER --network ${NETWORK_NAME} ${CONTAINER_PREFIX}jacs-async curl http://jacs-async:8080/api/rest-v2/async-services/dbMaintenance -H $userParam -H 'Accept: application/json' -H 'Content-Type: application/json' -d "${service_json_args}"
    exit 0
fi

if [[ "$1" == "backup" ]]; then
    if [[ "$2" == "mongo" ]]; then
        FILENAME=mongo-$(date +%Y%m%d%H%M%S).archive
        MONGO_BACKUPS_DIR=$BACKUPS_DIR/mongo
        echo "Dumping Mongo backup to $MONGO_BACKUPS_DIR/$FILENAME"
        echo "$SUDO $DOCKER run --rm -i -v $MONGO_BACKUPS_DIR:/backup -u $DOCKER_USER --network ${NETWORK_NAME} mongo:3.6 /usr/bin/mongodump --uri \"mongodb://${MONGODB_APP_USERNAME}:****@${MONGO_SERVER}&readPreference=secondary\" --archive=/backup/$FILENAME"
        $SUDO $DOCKER run --rm -i -v $MONGO_BACKUPS_DIR:/backup -u $DOCKER_USER --network ${NETWORK_NAME} mongo:3.6 /usr/bin/mongodump --uri "mongodb://${MONGODB_APP_USERNAME}:${MONGODB_APP_PASSWORD}@${MONGO_SERVER}&readPreference=secondary" --archive=/backup/$FILENAME
        exit 0
    elif [[ "$2" == "mysql" ]]; then
        FILENAME=flyportal-$(date +%Y%m%d%H%M%S).sql.gz
        MYSQL_BACKUPS_DIR=$BACKUPS_DIR/mysql
        echo "Dumping Mysql backup to $MYSQL_BACKUPS_DIR/$FILENAME"
        echo "$SUDO $DOCKER run --rm -i -v $MYSQL_BACKUPS_DIR:/backup -u $DOCKER_USER --network ${NETWORK_NAME} mysql:5.6.42 'bash -c /usr/bin/mysqldump -u ${MYSQL_JACS_USER} -p**** --all-databases | gzip >/backup/$FILENAME'"
        $SUDO $DOCKER run --rm -i -v $MYSQL_BACKUPS_DIR:/backup -u $DOCKER_USER --network ${NETWORK_NAME} mysql:5.6.42 'bash -c /usr/bin/mysqldump -u ${MYSQL_JACS_USER} -p${MYSQL_ROOT_PASSWORD} --all-databases | gzip >/backup/$FILENAME'
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
    echo "Container Management: `basename $0` [build|run|shell|push] [tool1] [tool2] .. [tooln]"
    echo "       You can combine multiple commands with a plus, e.g. build+push"
    echo "       For the up/down commands, the argument must be a tier name like 'dev' or 'prod'"
    echo 
    echo "Docker Compose: `basename $0` [up|down|ps|top] [environment] [--dbonly]"
    echo
    echo "Swarm Mode: `basename $0` [swarm|rmswarm] [environment] [--dbonly]"
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
            echo "$SUDO $DOCKER run -it -u $DOCKER_USER --rm $VNAME"
            $SUDO $DOCKER run -it -u $DOCKER_USER --rm $VNAME
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
            echo "$SUDO $DOCKER run -it -u $DOCKER_USER $VNAME /bin/bash"
            $SUDO $DOCKER run -it $VNAME /bin/bash
        fi

    elif [[ "$COMMAND" == "push" ]]; then

        echo "Will push $@ to $CONTAINER_PREFIX"

        for NAME in "$@"
        do
            # TODO: in the future, these images will be externally configured, and these conditionals can be removed
            if [[ "$NAME" == "workstation-site" ]]; then
                echo "Cannot push locally-configured image $NAME"
            elif [[ "$NAME" == "jacs-dashboard" ]]; then
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
                    echo " $SUDO $DOCKER push $VNAME"
                    echo "---------------------------------------------------------------------------------"
                    $SUDO $DOCKER push $VNAME
                    echo "---------------------------------------------------------------------------------"
                    echo " Pushing image for $LNAME"
                    echo " $SUDO $DOCKER push $LNAME"
                    echo "---------------------------------------------------------------------------------"
                    $SUDO $DOCKER push $LNAME
                fi
            fi
        done

    elif [[ "$COMMAND" == "swarm" ]]; then

        TIER=$1
        shift 1 # remove tier

        if [[ $1 == "--dbonly" ]]; then
            getyml $TIER "dbonly" "swarm" "YML"
        else
            getyml $TIER "" "swarm" "YML"
        fi

        echo "DOCKER_USER=\"$DOCKER_USER\" $DOCKER_COMPOSE $YML config > .tmp.swarm.yml"
        DOCKER_USER="$DOCKER_USER" $DOCKER_COMPOSE $YML config > .tmp.swarm.yml
        echo "$SUDO $DOCKER stack deploy --prune -c .tmp.swarm.yml $COMPOSE_PROJECT_NAME && sleep $SLEEP_TIME"
        $SUDO $DOCKER stack deploy --prune -c .tmp.swarm.yml $COMPOSE_PROJECT_NAME && sleep $SLEEP_TIME

    elif [[ "$COMMAND" == "rmswarm" ]]; then

        echo "$SUDO $DOCKER stack rm $COMPOSE_PROJECT_NAME && sleep $SLEEP_TIME"
        $SUDO $DOCKER stack rm $COMPOSE_PROJECT_NAME && sleep $SLEEP_TIME

    else
        # any other command is passed to docker-compose
        TIER=$1
        shift 1 # remove tier

        if [[ $1 == "--dbonly" ]]; then
            getyml $TIER "dbonly" "" "YML"
        else
            getyml $TIER "" "" "YML"
        fi

        echo "Bringing $COMMAND $TIER tier"
        echo "$SUDO DOCKER_USER="$DOCKER_USER" $DOCKER_COMPOSE $YML $COMMAND $@"
        $SUDO DOCKER_USER="$DOCKER_USER" $DOCKER_COMPOSE $YML $COMMAND $@
    fi

done

