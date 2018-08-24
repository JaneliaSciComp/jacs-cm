#!/bin/bash
#
# Management script for Docker containers
#

# Exit on error
set -e

# Constants
DOCKER="docker"
DOCKER_COMPOSE="docker-compose"
REGISTRY_SERVER="registry.int.janelia.org"
NAMESPACE="scsw"
SSH_PRIVATE_KEY=`cat ~/.ssh/id_dsa`

if [[ -z "$SSH_PRIVATE_KEY" ]]; then
    echo "You need to set up password-less SSH for Github before using this script"
fi


if [[ "$#" -lt 2 ]]; then
    echo "Usage: `basename $0` [build|run|shell|push|up|down] [tool1] [tool2] .. [tooln]"
    echo "       You can combine multiple commands with a plus, e.g. build+push"
    echo "       For the up/down commands, the argument must be a tier name like 'dev' or 'prod'"
    exit 1
fi

if [[ -z "$DOCKER_USER" ]]; then
    UNAME=jacs
    GNAME=jacsdata
    MYUID=$(id -u $UNAME)
    MYGID=`cut -d: -f3 < <(getent group $GNAME)`
    DOCKER_USER=$MYUID:$MYGID
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
            NAME=${NAME%/}
            if [[ -e $NAME/VERSION ]]; then
                VERSION=`cat $NAME/VERSION`
                CNAME=${REGISTRY_SERVER}/${NAMESPACE}/${NAME}
                VNAME=$CNAME:${VERSION}
                DNAME=$CNAME:dev
                LNAME=$CNAME:latest
                echo "---------------------------------------------------------------------------------"
                echo " Building image for $NAME"
                echo " sudo $DOCKER build --no-cache --build-arg SSH_PRIVATE_KEY=<hidden> -t $VNAME -t $DNAME -t $LNAME $NAME"
                echo "---------------------------------------------------------------------------------"
                sudo $DOCKER build --no-cache --build-arg SSH_PRIVATE_KEY="$SSH_PRIVATE_KEY" -t $VNAME -t $DNAME -t $LNAME $NAME
            else
                echo "No $NAME/VERSION found"
            fi
        done

    elif [[ "$COMMAND" == "run" ]]; then

        NAME=${1%/}
        if [[ -e $NAME/VERSION ]]; then
            VERSION=`cat $NAME/VERSION`
            CNAME=${REGISTRY_SERVER}/${NAMESPACE}/${NAME}
            VNAME=$CNAME:${VERSION}
            echo "sudo $DOCKER run -it -u $DOCKER_USER --rm $VNAME"
            sudo $DOCKER run -it -u $DOCKER_USER --rm $VNAME
        else
            echo "No $NAME/VERSION found"
        fi

    elif [[ "$COMMAND" == "shell" ]]; then

        NAME=${1%/}
        if [[ -e $NAME/VERSION ]]; then
            VERSION=`cat $NAME/VERSION`
            CNAME=${REGISTRY_SERVER}/${NAMESPACE}/${NAME}
            VNAME=$CNAME:${VERSION}
            echo "sudo $DOCKER run -it -u $DOCKER_USER $VNAME /bin/bash"
            sudo $DOCKER run -it $VNAME /bin/bash
        else
            echo "No $NAME/VERSION found"
        fi

    elif [[ "$COMMAND" == "push" ]]; then

        echo "Will push $@ to $REGISTRY_SERVER"

        for NAME in "$@"
        do
            NAME=${NAME%/}
            if [[ -e $NAME/VERSION ]]; then
                VERSION=`cat $NAME/VERSION`
                CNAME=${REGISTRY_SERVER}/${NAMESPACE}/${NAME}
                VNAME=$CNAME:${VERSION}
                DNAME=$CNAME:dev
                LNAME=$CNAME:latest
                echo "---------------------------------------------------------------------------------"
                echo " Pushing image for $VNAME"
                echo " sudo $DOCKER push $VNAME"
                echo "---------------------------------------------------------------------------------"
                sudo $DOCKER push $VNAME
                echo "---------------------------------------------------------------------------------"
                echo " Pushing image for $DNAME"
                echo " sudo $DOCKER push $DNAME"
                echo "---------------------------------------------------------------------------------"
                sudo $DOCKER push $DNAME
                echo "---------------------------------------------------------------------------------"
                echo " Pushing image for $LNAME"
                echo " sudo $DOCKER push $LNAME"
                echo "---------------------------------------------------------------------------------"
                sudo $DOCKER push $LNAME
            else
                echo "No $NAME/VERSION found"
            fi
        done

    elif [[ "$COMMAND" == "up" || "$COMMAND" == "down" ]]; then

        TIER=$1
        echo "Bringing $COMMAND $TIER tier"

        echo "sudo SSH_PRIVATE_KEY=<hidden> DOCKER_USER="$DOCKER_USER" $DOCKER_COMPOSE -f docker-compose.yml -f docker-compose.${TIER}.yml up"
        sudo SSH_PRIVATE_KEY="$SSH_PRIVATE_KEY" DOCKER_USER="$DOCKER_USER" $DOCKER_COMPOSE -f docker-compose.yml -f docker-compose.${TIER}.yml $COMMAND

    else
        echo "Unknown command: $COMMAND"
        exit 1
    fi

done
