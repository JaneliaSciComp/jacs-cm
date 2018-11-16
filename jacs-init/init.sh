#!/bin/bash

if [[ -z "$MONGO_INITDB_ROOT_USERNAME" ]]; then
    echo "You must specify the db-variables.env file containing the Mongo credentials"
    exit 1
fi

RABBIT_CONF=/app/jacs-messaging/rabbit/rabbit_queues_config.json

echo "Initializing RabbitMQ Data"
curl -v -u guest:guest -H "Content-Type: multipart/form-data" -H "Accept: application/json" -H "Expect:" -F file=@$RABBIT_CONF -X POST http://rabbitmq:15672/api/definitions

echo "Starting MongoDB replica set"
mongo mongodb://${MONGO_INITDB_ROOT_USERNAME}:${MONGO_INITDB_ROOT_PASSWORD}@mongo1:27017/${MONGO_INITDB_DATABASE} /app/mongo/replicaSet.js

echo "Initializing MongoDB Data"
for filename in /app/mongo/*.js; do
    mongo mongodb://${MONGO_INITDB_ROOT_USERNAME}:${MONGO_INITDB_ROOT_PASSWORD}@mongo1:27017,mongo2:27017,mongo3:27017/${MONGO_INITDB_DATABASE}?replicaSet=rsJacs $filename
    sleep 1
done

