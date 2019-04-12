#!/bin/bash
#
# Management script for JACS containers
#

# Exit on error
set -e

DIR=$(cd "$(dirname "$0")"; pwd)

if [[ ! -f $DIR/.env ]]; then
    echo "You need to configure your .env file before using this script. Get started by copying the template:"
    echo '  cp .env.template .env'
    exit 1
fi

# Parse environment
. $DIR/.env

if [[ -z "$DEPLOYMENT" ]]; then
    echo "Your .env file must define a DEPLOYMENT to use"
fi

echo "Using deployment $DEPLOYMENT"

# Constants
CONTAINER_DIRNAME=containers
DEPLOYMENTS_DIRNAME=deployments
CONTAINER_DIR="$DIR/$CONTAINER_DIRNAME"
DEPLOYMENT_DIR="$DIR/$DEPLOYMENTS_DIRNAME/$DEPLOYMENT"
CONTAINER_PREFIX="$NAMESPACE/"
if [[ ! -z $REGISTRY_SERVER ]]; then
    CONTAINER_PREFIX="$REGISTRY_SERVER/$CONTAINER_PREFIX"
fi
JACS_INIT_VERSION=`cat $CONTAINER_DIR/jacs-init/VERSION`

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

if [[ "$1" == "init-filesystem" ]]; then
    echo "Initializing file system..."
    echo "$SUDO $DOCKER run --rm --env-file .env -v $CONFIG_DIR:$CONFIG_DIR -v $DATA_DIR:$DATA_DIR -u $DOCKER_USER ${CONTAINER_PREFIX}jacs-init:${JACS_INIT_VERSION} /app/filesystem/run.sh"
    $SUDO $DOCKER run --rm --env-file .env -v $CONFIG_DIR:$CONFIG_DIR -v $DATA_DIR:$DATA_DIR -u $DOCKER_USER ${CONTAINER_PREFIX}jacs-init:${JACS_INIT_VERSION} /app/filesystem/run.sh
    echo ""
    echo "The filesystem is initialized. You should now edit the template files in $CONFIG_DIR to match your deployment environment."
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

if [[ "$1" == "backup" ]]; then
    if [[ "$2" == "mongo" ]]; then
        FILENAME=mongo-$(date +%Y%m%d%H%M%S).archive
        echo "Dumping Mongo backup to $MONGO_BACKUPS_DIR/$FILENAME"
        echo "$SUDO $DOCKER run --rm -i -v $MONGO_BACKUPS_DIR:/backup -u $DOCKER_USER --network ${NETWORK_NAME} mongo:3.6 /usr/bin/mongodump --uri \"mongodb://${MONGODB_APP_USERNAME}:****@${MONGO_SERVER}&readPreference=secondary\" --archive=/backup/$FILENAME"
        $SUDO $DOCKER run --rm -i -v $MONGO_BACKUPS_DIR:/backup -u $DOCKER_USER --network ${NETWORK_NAME} mongo:3.6 /usr/bin/mongodump --uri "mongodb://${MONGODB_APP_USERNAME}:${MONGODB_APP_PASSWORD}@${MONGO_SERVER}&readPreference=secondary" --archive=/backup/$FILENAME
        exit 0
    elif [[ "$2" == "mysql" ]]; then
        FILENAME=flyportal-$(date +%Y%m%d%H%M%S).sql.gz
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
    export TOKEN=$(sudo docker run -it --rm --env-file .env janeliascicomp/builder:latest /bin/bash -c "curl -sk --request POST --url https://${API_GATEWAY_EXPOSED_HOST}/SCSW/AuthenticationService/v1/authenticate --header \"Content-Type: application/json\" --data \"{\\\"username\\\":\\\"${JACS_USERNAME}\\\",\\\"password\\\":\\\"${JACS_PASSWORD}\\\"}\" | jq -r .token")
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
        echo "$SUDO $DOCKER stack deploy -c .tmp.swarm.yml $COMPOSE_PROJECT_NAME && sleep 2"
        $SUDO $DOCKER stack deploy -c .tmp.swarm.yml $COMPOSE_PROJECT_NAME && sleep 2
        echo "$SUDO $DOCKER service ls"
        $SUDO $DOCKER service ls

    elif [[ "$COMMAND" == "rmswarm" ]]; then

        echo "$SUDO $DOCKER stack rm $COMPOSE_PROJECT_NAME && sleep 5"
        $SUDO $DOCKER stack rm $COMPOSE_PROJECT_NAME && sleep 5

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

