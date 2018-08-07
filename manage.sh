#!/bin/bash
#
# Management script for Docker containers
#

DOCKER="sudo docker"
REGISTRY_SERVER="registry.int.janelia.org"
NAMESPACE="scsw"

# Exit on error
set -e

if [ "$#" -lt 2 ]; then
    echo "Usage: `basename $0` [build|run|shell|push] [tool1] [tool2] .. [tooln]"
    echo "       You can combine multiple commands with a plus, e.g. build+push"
    exit 1
fi

COMMANDS=$1
CMDARR=(${COMMANDS//+/ })
shift 1 # remove command parameter from args

for COMMAND in "${CMDARR[@]}"
do
    echo "Executing $COMMAND command on these targets: $@"

    if [ "$COMMAND" == "build" ]; then

        echo "Will build these images: $@"

        for NAME in "$@"
        do
            NAME=${NAME%/}
            VERSION=`cat $NAME/VERSION`
            CNAME=${REGISTRY_SERVER}/${NAMESPACE}/${NAME}
            VNAME=$CNAME:${VERSION}
            echo "---------------------------------------------------------------------------------"
            echo " Building image for $NAME"
            echo "---------------------------------------------------------------------------------"
            $DOCKER build -t $VNAME $NAME
        done

    elif [ "$COMMAND" == "run" ]; then

        NAME=${1%/}
        VERSION=`cat $NAME/VERSION`
        CNAME=${REGISTRY_SERVER}/${NAMESPACE}/${NAME}
        VNAME=$CNAME:${VERSION}

        $DOCKER run -it --rm $VNAME

    elif [ "$COMMAND" == "shell" ]; then

        NAME=${1%/}
        VERSION=`cat $NAME/VERSION`
        CNAME=${REGISTRY_SERVER}/${NAMESPACE}/${NAME}
        VNAME=$CNAME:${VERSION}

        $DOCKER run -it $VNAME /bin/bash

    elif [ "$COMMAND" == "push" ]; then

        echo "Will push $@ to $REGISTRY_SERVER"

        for NAME in "$@"
        do
            NAME=${NAME%/}
            VERSION=`cat $NAME/VERSION`
            CNAME=${REGISTRY_SERVER}/${NAMESPACE}/${NAME}
            VNAME=$CNAME:${VERSION}
            echo "---------------------------------------------------------------------------------"
            echo " Pushing image for $VNAME"
            echo "---------------------------------------------------------------------------------"
            $DOCKER push $VNAME
        done

    else
        echo "Unknown command: $COMMAND"
        exit 1
    fi

done
