#!/bin/bash
#
# Management script for JACS containers.
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
. .env

if [[ -z "$DEPLOYMENT" ]]; then
    echo "Your .env file must define a DEPLOYMENT to use"
fi

echo "Using deployment $DEPLOYMENT"

# Constants
CONTAINER_DIRNAME=containers
DEPLOYMENTS_DIRNAME=deployments
CONTAINER_DIR="$DIR/$CONTAINER_DIRNAME"
DEPLOYMENT_DIR="$DIR/$DEPLOYMENTS_DIRNAME/$DEPLOYMENT"
CONTAINER_PREFIX="$REGISTRY_SERVER/$NAMESPACE/"
NETWORK_NAME="${COMPOSE_PROJECT_NAME}_jacs-net"
MONGO_SERVER="mongo1:27017,mongo2:27017,mongo3:27017/jacs?replicaSet=rsJacs&authSource=admin"

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

if [[ "$1" == "init-filesystem" ]]; then
    echo "Initializing file system..."
    echo "$SUDO $DOCKER run --rm --env-file .env -v $CONFIG_DIR:$CONFIG_DIR -v $DATA_DIR:$DATA_DIR -u $DOCKER_USER ${CONTAINER_PREFIX}jacs-init:latest /app/init-filesystem/run.sh"
    $SUDO $DOCKER run --rm --env-file .env -v $CONFIG_DIR:$CONFIG_DIR -v $DATA_DIR:$DATA_DIR -u $DOCKER_USER ${CONTAINER_PREFIX}jacs-init:latest /app/init-filesystem/run.sh
    echo ""
    echo "The filesystem is initialized. You should now edit the template files in $CONFIG_DIR to match your deployment environment."
    echo ""
    exit 0
fi


if [[ "$1" == "init-databases" ]]; then
    echo "Initializing databases..."
    echo "$SUDO $DOCKER run --rm --env-file .env -u $DOCKER_USER --network ${NETWORK_NAME} ${CONTAINER_PREFIX}jacs-init:latest /app/init-databases/run.sh"
    $SUDO $DOCKER run --rm --env-file .env -u $DOCKER_USER --network ${NETWORK_NAME} ${CONTAINER_PREFIX}jacs-init:latest /app/init-databases/run.sh
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
    echo "$SUDO $DOCKER run -it -u $DOCKER_USER --network ${NETWORK_NAME} mysql:5.6.42 /usr/bin/mysql -u ${MYSQL_JACS_USER} -p${MYSQL_ROOT_PASSWORD} -h mysql ${MYSQL_DATABASE}"
    $SUDO $DOCKER run -it -u $DOCKER_USER --network ${NETWORK_NAME} mysql:5.6.42 /usr/bin/mysql -u ${MYSQL_JACS_USER} -p${MYSQL_ROOT_PASSWORD} -h mysql ${MYSQL_DATABASE}
    exit 0
fi

if [[ "$1" == "login" ]]; then
    read -p "Username: " JACS_USERNAME
    read -s -p "Password: " JACS_PASSWORD
    echo 
    echo Response from Authentication Service:
    curl -k --request POST --url https://${API_GATEWAY_EXPOSED_HOST}/SCSW/AuthenticationService/v1/authenticate \
        --header 'content-type: application/json' --data "{\"username\":\"${JACS_USERNAME}\",\"password\":\"${JACS_PASSWORD}\"}"
    exit 0
fi

if [[ "$#" -lt 2 ]]; then
    echo "Usage: `basename $0` [build|run|shell|push|up|down] [tool1] [tool2] .. [tooln]"
    echo "       You can combine multiple commands with a plus, e.g. build+push"
    echo "       For the up/down commands, the argument must be a tier name like 'dev' or 'prod'"
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
            NAME=${NAME/$CONTAINER_DIRNAME\/}
            NAME=${NAME%/}
            CDIR="$CONTAINER_DIR/$NAME"
            if [[ -e $CDIR/VERSION ]]; then
                VERSION=`cat $CDIR/VERSION`
                CNAME=${CONTAINER_PREFIX}${NAME}
                VNAME=$CNAME:${VERSION}
                LNAME=$CNAME:latest
                APP_TAG=master
                if [[ -e $CDIR/APP_TAG ]]; then
                    APP_TAG=$(cat $CDIR/APP_TAG)
                fi
                echo "---------------------------------------------------------------------------------"
                echo " Building image for $NAME"
                echo " $SUDO $DOCKER build --no-cache --build-arg APP_TAG=$APP_TAG --build-arg API_GATEWAY_EXPOSED_HOST=$API_GATEWAY_EXPOSED_HOST -t $VNAME -t $LNAME $CDIR"
                echo "---------------------------------------------------------------------------------"
                $SUDO $DOCKER build --no-cache --build-arg APP_TAG=$APP_TAG --build-arg API_GATEWAY_EXPOSED_HOST=$API_GATEWAY_EXPOSED_HOST -t $VNAME -t $LNAME $CDIR
            else
                echo "No $CDIR/VERSION found"
            fi
        done

    elif [[ "$COMMAND" == "run" ]]; then
        NAME=${1/$CONTAINER_DIRNAME\/}
        NAME=${NAME%/}
        CDIR="$CONTAINER_DIR/$NAME"
        if [[ -e $CDIR/VERSION ]]; then
            VERSION=`cat $CDIR/VERSION`
            CNAME=${CONTAINER_PREFIX}${NAME}
            VNAME=$CNAME:${VERSION}
            echo "$SUDO $DOCKER run -it -u $DOCKER_USER --rm $VNAME"
            $SUDO $DOCKER run -it -u $DOCKER_USER --rm $VNAME
        else
            echo "No $CDIR/VERSION found"
        fi

    elif [[ "$COMMAND" == "shell" ]]; then

        NAME=${1/$CONTAINER_DIRNAME\/}
        NAME=${NAME%/}
        CDIR="$CONTAINER_DIR/$NAME"
        if [[ -e $CDIR/VERSION ]]; then
            VERSION=`cat $CDIR/VERSION`
            CNAME=${CONTAINER_PREFIX}${NAME}
            VNAME=$CNAME:${VERSION}
            echo "$SUDO $DOCKER run -it -u $DOCKER_USER $VNAME /bin/bash"
            $SUDO $DOCKER run -it $VNAME /bin/bash
        else
            echo "No $CDIR/VERSION found"
        fi

    elif [[ "$COMMAND" == "push" ]]; then

        echo "Will push $@ to $CONTAINER_PREFIX"

        for NAME in "$@"
        do
            NAME=${NAME/$CONTAINER_DIRNAME\/}
            NAME=${NAME%/}
            CDIR="$CONTAINER_DIR/$NAME"
            if [[ -e $CDIR/VERSION ]]; then
                VERSION=`cat $CDIR/VERSION`
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
            else
                echo "No $CDIR/VERSION found"
            fi
        done

    else
        # any other command is passed to docker-compose
        TIER=$1
        shift 1 # remove tier
        if [[ $1 == "--dbonly" ]]; then
            shift 1 # remove dbonly flag
            YML="-f $DEPLOYMENT_DIR/docker-compose-db.yml"
            if [ -n "${TIER}" ]; then
                if [[ -e "$DEPLOYMENT_DIR/docker-compose.${TIER}-db.yml" ]]; then
                    YML="$YML -f $DEPLOYMENT_DIR/docker-compose.${TIER}-db.yml"
                fi
            fi
        else
            YML="-f $DEPLOYMENT_DIR/docker-compose-db.yml -f $DEPLOYMENT_DIR/docker-compose-app.yml"
            if [ -n "${TIER}" ]; then
                if [[ -e "$DEPLOYMENT_DIR/docker-compose.${TIER}-db.yml" ]]; then
                    YML="$YML -f $DEPLOYMENT_DIR/docker-compose.${TIER}-db.yml"
                fi
                if [[ -e "$DEPLOYMENT_DIR/docker-compose.${TIER}-app.yml" ]]; then
                    YML="$YML -f $DEPLOYMENT_DIR/docker-compose.${TIER}-app.yml"
                fi
                if [[ -e "$DEPLOYMENT_DIR/docker-compose.${TIER}.yml" ]]; then
                    YML="$YML -f $DEPLOYMENT_DIR/docker-compose.${TIER}.yml"
                fi
            fi
        fi
        echo "Bringing $COMMAND $TIER tier"
        echo "$SUDO DOCKER_USER="$DOCKER_USER" $DOCKER_COMPOSE $YML $COMMAND $@"
        $SUDO DOCKER_USER="$DOCKER_USER" $DOCKER_COMPOSE $YML $COMMAND $@

    fi

done
