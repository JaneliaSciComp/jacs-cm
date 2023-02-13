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
STACKS_DIRNAME=stacks
CONTAINER_DIR="$DIR/$CONTAINER_DIRNAME"
SLEEP_TIME=6

# Container versioning (exported so that they're available for use in docker compose files)
JACS_SYNC_CONTAINER=jacs-compute
JACS_ASYNC_CONTAINER=jacs-async

export API_GATEWAY_VERSION=`cat $CONTAINER_DIR/api-gateway/VERSION`
export BUILDER_VERSION=`cat $CONTAINER_DIR/builder/VERSION`
export JACS_INIT_VERSION=`cat $CONTAINER_DIR/jacs-init/VERSION`
export JACS_ASYNC_COMPUTE_VERSION=`cat $CONTAINER_DIR/${JACS_ASYNC_CONTAINER}/VERSION`
export JACS_SYNC_COMPUTE_VERSION=`cat $CONTAINER_DIR/${JACS_SYNC_CONTAINER}/VERSION`
export JACS_DASHBOARD_VERSION=`cat $CONTAINER_DIR/jacs-dashboard/VERSION`
export JACS_STORAGE_VERSION=`cat $CONTAINER_DIR/jacs-storage/VERSION`
export JACS_MESSAGING_VERSION=`cat $CONTAINER_DIR/jacs-messaging/VERSION`
export IPP_VERSION=`cat $CONTAINER_DIR/ipp/VERSION`
export SOLR_SEARCH_VERSION=`cat $CONTAINER_DIR/solr-search.9.1/VERSION`
export WORKSTATION_VERSION=`cat $CONTAINER_DIR/workstation-site/VERSION`
export WORKSTATION_HORTA_VERSION=`cat $CONTAINER_DIR/workstation-site-horta/VERSION`

# Environment file
ENV_CONFIG=${ENV_CONFIG:-.env.config}
if [[ ! -f $DIR/$ENV_CONFIG ]]; then
    echo "You need to configure your $ENV_CONFIG file before using this script. Get started by copying the template:"
    echo "  cp .env.template $ENV_CONFIG"
    exit 1
fi

# Start with uninterpolated environment
. $DIR/$ENV_CONFIG

if [[ -n $ENV_FILE_PARAM ]]; then
    ENV_PARAM="--env-file $ENV_FILE_PARAM"
else
    ENV_PARAM=
fi

# Chicken/egg: there's no .env parsing for building the builder because the builder is necessary for .env parsing
if [[ "$@" != "build builder" ]]; then

    # Check to see if .env needs to be regenerated
    regen=false
    if [[ -e .env ]]; then
        set +e
        # parse the previous SHA1 sum out of the file and check it against the current sum
        sed 's|# ||' .env | sed -n 4p | sha1sum --status -c - > /dev/null
        res=$?
        if [[ $res -eq "1" ]]; then
            # Sum doesn't match, regenerate the .env file
            regen=true
        fi
        set -e
    else
        # Generate the .env file if it doesn't exist
        regen=true
    fi

    if ($regen); then
        # Generate environment
        echo "Generating .env from .env.config"
        echo "##################################################################################" > $DIR/.env
        echo "# This file was automatically generated from $ENV_CONFIG. Edit that instead!" >> $DIR/.env
        echo "##################################################################################" >> $DIR/.env
        echo "# "`sha1sum .env.config` >> $DIR/.env
        echo "" >> $DIR/.env
        $SUDO $DOCKER run --rm -v $DIR/$ENV_CONFIG:/env $NAMESPACE/builder:$BUILDER_VERSION /bin/bash -c "/usr/local/bin/multisub.sh /env"  >> $DIR/.env
    fi

    # Parse environment
    echo "Parsing .env"
    . $DIR/.env
fi

if [[ -z "$DEPLOYMENT" ]]; then
    echo "Your $ENV_CONFIG file must define a DEPLOYMENT to use"
fi
DEPLOYMENT_DIR="$DIR/$DEPLOYMENTS_DIRNAME/$DEPLOYMENT"
echo "Using deployment $DEPLOYMENT defined by $DEPLOYMENT_DIR"
ELK_DEPLOYMENT_DIR="$DIR/$STACKS_DIRNAME/elk"

# More variables
CONTAINER_PREFIX="$NAMESPACE/"
PUBLISHING_PREFIX="$PUBLISHING_NAMESPACE/"
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
        # custom JADE volume mounts
        if [[ -e "local/docker-jade-volumes.yml" ]]; then
            YML="$YML -f local/docker-jade-volumes.yml"
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

#
# Find the contents of the VERSION file for the given container name (as returned by getcontainer)
#
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

        if [[ $NAME == "workstation-site" ]]; then
        
            if [[ ! -z $WORKSTATION_CLIENT_MEM ]]; then
                BUILD_ARGS="$BUILD_ARGS --build-arg WORKSTATION_CLIENT_MEM=$WORKSTATION_CLIENT_MEM"
            fi

            if [[ ! -e $CDIR/cert.crt || ! -e $CDIR/cert.key ]]; then
                echo
                echo "Building workstation-site requires cert.crt and cert.key to exist in $CDIR"
                echo "You should copy your certs there manually before building. They will be ignored by Git."
                echo
                exit 1
            fi
        
        fi

        echo "---------------------------------------------------------------------------------"
        echo " Building image for $NAME"
        echo "---------------------------------------------------------------------------------"
        set -x
        $SUDO $DOCKER build --no-cache $BUILD_ARGS --label "version=$APP_TAG" -t $VNAME -t $LNAME $CDIR
        set +x
    fi
}

#
# Publish existing containers to another registry.
#
function publish {
    local _name="$1"
    getcontainer $_name "NAME"
    getversion $NAME "VERSION"
    CDIR="$CONTAINER_DIR/$NAME"
    if [[ ! -z $VERSION ]]; then
        CNAME=${CONTAINER_PREFIX}${NAME}
        PNAME=${PUBLISHING_PREFIX}${NAME}
        LNAME=$CNAME:latest
        PLNAME=$PNAME:latest
        PVNAME=$PNAME:${VERSION}

        echo "---------------------------------------------------------------------------------"
        echo " Publishing image $LNAME"
        echo "---------------------------------------------------------------------------------"
        set -x
        $SUDO $DOCKER tag $LNAME $PLNAME
        $SUDO $DOCKER tag $LNAME $PVNAME
        $SUDO $DOCKER push $PLNAME
        $SUDO $DOCKER push $PVNAME
        set +x
    fi
}


# What user to run containers with
if [[ -z "$DOCKER_USER" ]]; then
    if [[ -z "$UNAME" || -z "$GNAME" ]]; then
        echo "Your .env file needs to either define the UNAME and GNAME variables, or the DOCKER_USER variable."
        exit 1
    fi
    MYUID=$(id -u $UNAME)
    if [[ `uname` == "Darwin" ]]; then
        # Macs don't have getent
        MYGID=`dscl . -read /Groups/$GNAME | awk '($1 == "PrimaryGroupID:") { print $2 }'`
    else
        # Find the group id for the given group name
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

if [[ "$1" == "versions" ]]; then
    echo
    echo "builder: $BUILDER_VERSION"
    echo "workstation-site: $WORKSTATION_VERSION"
    echo "workstation-horta-site: $WORKSTATION_HORTA_VERSION"
    echo "api-gateway: $API_GATEWAY_VERSION"
    echo "jacs-init: $JACS_INIT_VERSION"
    echo "jacs-compute: $JACS_SYNC_COMPUTE_VERSION"
    echo "jacs-async: $JACS_ASYNC_COMPUTE_VERSION"
    echo "jacs-dashboard: $JACS_DASHBOARD_VERSION"
    echo "jacs-storage: $JACS_STORAGE_VERSION"
    echo "jacs-messaging: $JACS_MESSAGING_VERSION"
    echo "solr-search: $SOLR_SEARCH_VERSION"
    echo "ipp: $IPP_VERSION"
    echo
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
    DOCKER_USER="$DOCKER_USER" $DOCKER_COMPOSE $ENV_PARAM $YML config > .tmp.swarm.yml
    DEPLOY_YML_CFG=`echo $YML | sed s/-f/-c/g`
    set -a && . .env && set +a
    DOCKER_USER=$DOCKER_USER $SUDO $DOCKER stack deploy --prune $DEPLOY_YML_CFG $STACK_NAME && sleep 10
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
    $SUDO $DOCKER run $ENV_PARAM -v ${REDUNDANT_STORAGE}:${REDUNDANT_STORAGE} -v ${NON_REDUNDANT_STORAGE}:${NON_REDUNDANT_STORAGE} -u $DOCKER_USER ${CONTAINER_PREFIX}jacs-init:${JACS_INIT_VERSION} /app/filesystem/run.sh
    set +x
    echo ""
    echo "The local filesystem is initialized. You should now edit the template files in $CONFIG_DIR to match your deployment environment."
    echo ""
    exit 0
fi

if [[ "$1" == "init-databases" ]]; then
    echo "Initializing databases..."
    set -x
    $SUDO $DOCKER run $ENV_PARAM --rm -u $DOCKER_USER --network ${NETWORK_NAME} ${CONTAINER_PREFIX}jacs-init:${JACS_INIT_VERSION} /app/databases/run.sh
    set +x
    echo ""
    echo "Databases have been initialized."
    echo ""
    exit 0
fi

if [[ "$1" == "mongo" ]]; then
    shift
    mongo_tool="mongo"
    if [[ "$1" == "-tool" ]]; then
        mongo_tool="$2"
        shift
        shift
    fi
    tty_param="-it"
    if [[ "$1" == "-notty" ]]; then
        tty_param=""
        shift
    fi
    run_options=""
    if [[ "$1" == "-run-opts" ]]; then
        run_options="$2"
        shift
        shift
    fi
    echo "Opening MongoDB shell..."
    set -x
    $SUDO $DOCKER run ${tty_param} \
    -u $DOCKER_USER \
    --network ${NETWORK_NAME} \
    ${run_options} \
    mongo:${MONGO_VERSION} \
    /usr/bin/${mongo_tool} "mongodb://${MONGODB_APP_USERNAME}:${MONGODB_APP_PASSWORD}@${MONGO_URL}" "$@"
    set +x
    exit 0
fi

if [[ "$1" == "mongo-backup" ]]; then
    shift
    if [[ $# == 0 ]]; then
        echo "$0 mongo-backup <backup location>"
        exit 1
    fi
    backupLocation="$1"
    echo "MongoDB backup to $backupLocation..."
    set -x
    $SUDO $DOCKER run $ENV_PARAM \
    --network ${NETWORK_NAME} \
    -v $backupLocation:$backupLocation \
    mongo:${MONGO_VERSION} \
    /usr/bin/mongodump "mongodb://${MONGODB_APP_USERNAME}:${MONGODB_APP_PASSWORD}@${MONGO_URL}&readPreference=secondary" --out=${backupLocation} && \
    set +x
    exit 0
fi

if [[ "$1" == "mongo-restore" ]]; then
    shift
    if [[ $# == 0 ]]; then
        echo "$0 mongo-restore <backup location>"
        exit 1
    fi
    backupLocation="$1"
    echo "MongoDB restore from $backupLocation..."
    set -x
    $SUDO $DOCKER run $ENV_PARAM \
    --network ${NETWORK_NAME} \
    -v $backupLocation:$backupLocation \
    mongo:${MONGO_VERSION} \
    /usr/bin/mongorestore "mongodb://${MONGODB_APP_USERNAME}:${MONGODB_APP_PASSWORD}@${MONGO_URL}" ${backupLocation}
    set +x
    exit 0
fi

if [[ "$1" == "dbMaintenance" ]]; then
    echo "Perform DB maintenance..."
    shift
    if [[ $# == 0 ]]; then
        echo "$0 dbMaintenance <username> [-refreshIndexes] [-refreshPermissions] [-refreshTmSampleSync]"
        exit 1
    fi
    userParam=username:"$1"
    shift

    service_args=()

    while [[ $# -gt 0 ]]; do
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
        -refreshTmSampleSync)
        service_args+=(\"-refreshTmSampleSync\")
        ;;
        -h|--help)
        echo "$0 dbMaintenance <username> [-refreshIndexes] [-refreshPermissions] [-refreshTmSampleSync]"
        exit 0
        ;;
        *)
        # invalid arg
        echo "$0 dbMaintenance <username> [-refreshIndexes] [-refreshPermissions] [-refreshTmSampleSync]"
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
        $SUDO $DOCKER run $ENV_PARAM -u $DOCKER_USER --network ${NETWORK_NAME} ${CONTAINER_PREFIX}jacs-async curl ${JACS_ASYNC_SERVER}/api/rest-v2/async-services/dbMaintenance -H $userParam -H 'Accept: application/json' -H 'Content-Type: application/json' -d "${service_json_args}" -H "Authorization: APIKEY $JACS_API_KEY"
    set +x

    exit 0
fi

if [[ "$1" == "rebuildSolrIndex" ]]; then
    echo "Rebuilding SOLR index ..."
    shift

    if [[ $# == 0 ]]; then
        echo "$0 rebuildSolrIndex <username>"
        exit 1
    fi
    USERNAME=$1

    set -x
    $SUDO $DOCKER run $ENV_PARAM \
    -u $DOCKER_USER \
    --network ${NETWORK_NAME} \
    ${CONTAINER_PREFIX}${JACS_ASYNC_CONTAINER}:${JACS_ASYNC_COMPUTE_VERSION} \
    curl -X POST http://jacs-async:8080/api/rest-v2/async-services/solrIndexBuilder \
    -H 'Accept: application/json' \
    -H 'Content-Type: application/json' \
    -H "username: ${USERNAME}" \
    -d '{ "args": [], "resources": {} }'
    set +x

    exit 0
fi

if [[ "$1" == "login" ]]; then
    read -p "Username: " JACS_USERNAME
    read -s -p "Password: " JACS_PASSWORD
    echo
    export TOKEN=$($SUDO docker run $ENV_PARAM \
                    -it --rm $NAMESPACE/builder:latest \
                    /bin/bash -c "curl -sk --request POST --url https://${API_GATEWAY_EXPOSED_HOST}/SCSW/AuthenticationService/v1/authenticate --header \"Content-Type: application/json\" --data \"{\\\"username\\\":\\\"${JACS_USERNAME}\\\",\\\"password\\\":\\\"${JACS_PASSWORD}\\\"}\" | jq -r .token")
    echo "Token generated. Export it to your environment like this:"
    echo "export TOKEN=$TOKEN"
    exit 0
fi

if [[ "$1" == "createUserFromJson" ]]; then
    if [[ "$#" -lt 2 ]]; then
        echo "Missing JSON input:"
        echo "Usage manage.sh createUserFromJson <jsoninput>"
        exit 1
    fi
    set -x
    cat $2
    d=$(dirname $2)
    $SUDO $DOCKER run $ENV_PARAM \
        -u $DOCKER_USER \
        --network ${NETWORK_NAME} \
        -v $d:$d \
        ${CONTAINER_PREFIX}jacs-init:${JACS_INIT_VERSION} \
        curl -i -X PUT http://jacs-sync:8080/api/rest-v2/data/user \
        -H "Authorization: APIKEY $JACS_API_KEY" \
        -H "Content-Type: application/json" \
        --retry 5 \
        --retry-delay 60 \
        --data @$2
    set +x
    exit 0
fi

if [[ "$#" -lt 1 ]]; then
    echo
    echo "This script simplifies deployment and management of the JACS system. Usage details:"
    echo
    echo "Container Management:"
    echo "  versions - Print all the container versions that will be built and deployed"
    echo "  build [containerName] - Build the given container, found under ./containers/"
    echo "  run [containerName] - Run the given container"
    echo "  shell [containerName] - Shell into the given container"
    echo "  push [containerName] - Push the built container to a remote repository defined by the NAMESPACE variable in the .env.config file"
    echo "  publish [containerName] - Push the built container to a remote repository defined by the PUBLISHING_NAMESPACE variable in the .env.config file"
    echo
    echo "Installation: "
    echo "  init-local-filesystem - Initialize the local filesystem on the current host"
    echo "  init-filesystems - Initalize all filesystems in the Swarm"
    echo "  init-databases - Initialize the databases"
    echo
    echo "Swarm Deployment: [start|stop]"
    echo
    echo "Compose Deployment: compose [up|down|ps|top]"
    echo
    echo "Service Management:"
    echo "  status - Print the status of all services"
    echo "  status [service] - Print the status of the specified service"
    echo "  restart [service] - Fetch the latest container for the service and redeploy it"
    echo "  mongo - Open shell into the Mongo database"
    echo "  mongo-backup <backup location> - Backup Mongo database"
    echo "  dbMaintenance - Ensure that all databases indexes and denormalizations are up-to-date"
    echo "  rebuildSolrIndex - Rebuild the SOLR index from scratch"
    echo "  backup [mongo] - Generate a database backup into $BACKUPS_DIR"
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

    elif [[ "$COMMAND" == "publish" ]]; then

        echo "Will publish these images: $@"

        for NAME in "$@"
        do
            publish $NAME
        done

    elif [[ "$COMMAND" == "run" ]]; then
        getcontainer $1 "NAME"
        getversion $NAME "VERSION"
        CDIR="$CONTAINER_DIR/$NAME"
        shift
        if [[ ! -z $VERSION ]]; then
            CNAME=${CONTAINER_PREFIX}${NAME}
            VNAME=$CNAME:${VERSION}
            set -x
            $SUDO $DOCKER run -it -u $DOCKER_USER --rm $VNAME "$@"
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
        done

    elif [[ "$COMMAND" == "start" ]]; then

        if [[ $1 == "--dbonly" ]]; then
            getyml $STAGE "dbonly" "swarm" "YML"
        else
            getyml $STAGE "" "swarm" "YML"
        fi

        set -x
        # .tmp.swarm.yml is only saved for reference not because it is actually used
        # the file generated by config is not usable by docker stack because the version is missing
        # and the depends on are not compatible with the latest version
        DOCKER_USER="$DOCKER_USER" $DOCKER_COMPOSE $ENV_PARAM $YML config > .tmp.swarm.yml
        # the workaround is to use multiple configurations and set the environment from .env file
        DEPLOY_YML_CFG=`echo $YML | sed s/-f/-c/g`
        set -a && . .env && set +a
        export DOCKER_USER DOCKER_GID=$MYGID && $SUDO $DOCKER stack deploy --prune $DEPLOY_YML_CFG $COMPOSE_PROJECT_NAME && sleep $SLEEP_TIME
        set +x

    elif [[ "$COMMAND" == "start-elk" ]]; then

        set -a && . .env && set +a
        $SUDO $DOCKER stack deploy -c $ELK_DEPLOYMENT_DIR/docker-compose.yml ${COMPOSE_PROJECT_NAME}_elk && sleep $SLEEP_TIME

    elif [[ "$COMMAND" == "stop" ]]; then

        set -x
        $SUDO $DOCKER stack rm $COMPOSE_PROJECT_NAME && sleep $SLEEP_TIME
        set +x

    elif [[ "$COMMAND" == "stop-elk" ]]; then

        $SUDO $DOCKER stack rm ${COMPOSE_PROJECT_NAME}_elk && sleep $SLEEP_TIME

    elif [[ "$COMMAND" == "compose" ]]; then

        COMPOSE_COMMAND=$1
        shift 1 # remove compose command

        if [[ $1 == "--dbonly" ]]; then
            echo "Start docker-compose only with DB services"
            shift 1 # remove dbonly flag
            # if dbonly 
            getyml $STAGE "dbonly" "" "YML"
        else
            getyml $STAGE "" "" "YML"
        fi

        OPTS="$@"
        echo "Bringing $COMPOSE_COMMAND ($STAGE)"
        set -x
        DOCKER_USER="$DOCKER_USER" DOCKER_GID=$MYGID $DOCKER_COMPOSE $ENV_PARAM $YML $COMPOSE_COMMAND $OPTS
        set +x

    else
        echo "Unrecognized command: $COMMAND"
        exit 1
    fi

done
