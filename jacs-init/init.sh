#!/bin/bash

if [[ -z "$MONGODB_INIT_ROOT_USERNAME" ]]; then
    echo "You must specify the env file containing the Mongo initialization parameters"
    exit 1
fi

RABBIT_CONF=/app/jacs-messaging/rabbit/rabbit_queues_config.json

echo "Initializing RabbitMQ Data"
curl -v -u guest:guest -H "Content-Type: multipart/form-data" -H "Accept: application/json" -H "Expect:" -F file=@$RABBIT_CONF -X POST http://rabbitmq:15672/api/definitions

echo "Starting MongoDB replica set"
mongo mongodb://${MONGODB_INIT_ROOT_USERNAME}:${MONGODB_INIT_ROOT_PASSWORD}@mongo1:27017/${MONGODB_INIT_DATABASE} /app/mongo/replicaSet.js

echo "Initializing MongoDB Users"

cat >/tmp/createUserAdmin.js <<EOL
db.createUser(
  {
    user: "${MONGODB_ADMIN_USERNAME}",
    pwd: "${MONGODB_ADMIN_PASSWORD}",
    roles: ["root"],
    passwordDigestor : "server"
  });
EOL

cat >/tmp/createUserJacs.js <<EOL
db.createUser(
  {
    user: "${MONGODB_JACS_USERNAME}",
    pwd: "${MONGODB_JACS_PASSWORD}",
    roles: [ { role: "readWrite", db: "jacs" } ],
    passwordDigestor : "server"
  });
EOL

cat >/tmp/createUserJade.js <<EOL
db.createUser(
  {
    user: "${MONGODB_JADE_USERNAME}",
    pwd: "${MONGODB_JADE_PASSWORD}",
    roles: [ { role: "readWrite", db: "jade" } ],
    passwordDigestor : "server"
  });
EOL

for filename in /tmp/*.js; do
    mongo mongodb://${MONGODB_INIT_ROOT_USERNAME}:${MONGODB_INIT_ROOT_PASSWORD}@mongo1:27017,mongo2:27017,mongo3:27017/${MONGODB_INIT_DATABASE}?replicaSet=rsJacs $filename
    sleep 1
done

