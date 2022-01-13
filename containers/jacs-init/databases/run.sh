#!/bin/bash
#
# Initializes the database content.
#

DIR=$(cd "$(dirname "$0")"; pwd)

function init_rabbitmq() {
    echo
    echo "Customizing RabbitMQ Environment"
    local RABBIT_CONF=$DIR/rabbitmq/rabbit_queues_config.json
    local TMP_RABBIT_CONF=/tmp/rabbit_queues_config.json

    cp $RABBIT_CONF $TMP_RABBIT_CONF

    local RABBITMQ_PASSWORD_HASH=$(python $DIR/rabbitmq/hash.py $RABBITMQ_PASSWORD)

    sed -i -e "s@RABBITMQ_USER@${RABBITMQ_USER}@g" $TMP_RABBIT_CONF
    sed -i -e "s@RABBITMQ_PASSWORD@${RABBITMQ_PASSWORD_HASH}@g" $TMP_RABBIT_CONF

    echo "RabbitMQ config: $(cat $TMP_RABBIT_CONF)"

    echo
    echo "Initializing RabbitMQ Data"
    curl -v -u guest:guest -H "Content-Type: multipart/form-data" -H "Accept: application/json" -H "Expect:" -F file=@$TMP_RABBIT_CONF http://rabbitmq:15672/api/definitions
    curl -v -u $RABBITMQ_USER:$RABBITMQ_PASSWORD -X DELETE http://rabbitmq:15672/api/users/guest

    echo "Initialized RabbitMQ"
}

function init_mongo() {

  if [[ -z "$MONGODB_INIT_ROOT_USERNAME" ]]; then
      echo "No MONGODB_INIT_ROOT_USERNAME is specified. Mongo will not be initialized."
      return 1
  fi

  echo
  echo "Starting MongoDB replica set"
  mongo mongodb://${MONGODB_INIT_ROOT_USERNAME}:${MONGODB_INIT_ROOT_PASSWORD}@mongo1:27017/${MONGODB_INIT_DATABASE} $DIR/mongo/replicaSet.js

  echo
  echo "Initializing MongoDB Users"
  cat >/tmp/createUserJacs.js <<-EOL
  db.createUser(
  {
    user: "${MONGODB_APP_USERNAME}",
    pwd: "${MONGODB_APP_PASSWORD}",
    roles: [ { role: "readWriteAnyDatabase", db: "admin" } ],
    passwordDigestor : "server"
  });
  EOL

  REPLICA_HOSTS=mongo1:27017,mongo2:27017,mongo3:27017
  for filename in /tmp/*.js; do
      mongo mongodb://${MONGODB_INIT_ROOT_USERNAME}:${MONGODB_INIT_ROOT_PASSWORD}@${REPLICA_HOSTS}/${MONGODB_INIT_DATABASE}?replicaSet=rsJacs $filename
      sleep 1
  done

  for filepath in $DIR/mongo/*.json; do
      filename=${filepath##*/}
      collection=${filename%.*}
      echo
      echo "Initializing default data from $filepath to $collection collection"
      echo "mongoimport --authenticationDatabase=admin -u $MONGODB_APP_USERNAME -p *** -h rsJacs/$REPLICA_HOSTS --db jacs --collection $collection $filepath"
      mongoimport --authenticationDatabase admin \
                  -u $MONGODB_APP_USERNAME -p $MONGODB_APP_PASSWORD \
                  -h rsJacs/$REPLICA_HOSTS \
                  --db jacs --collection $collection $filepath
      sleep 1
  done

  return 0
}

init_rabbitmq

init_mongo