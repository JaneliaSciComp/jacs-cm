#!/bin/bash

if [[ -z "$MONGODB_INIT_ROOT_USERNAME" ]]; then
    echo "You must specify the env file containing the Mongo initialization parameters"
    exit 1
fi

RABBIT_CONF=/app/jacs-messaging/rabbit/rabbit_queues_config.json

echo "Customizing RabbitMQ Environment"
sed -i -e 's@RABBITMQ_ADMIN_PASSWORD@'"$RABBITMQ_ADMIN_PASSWORD"'@g' $RABBIT_CONF
sed -i -e 's@RABBITMQ_GUEST_PASSWORD@'"$RABBITMQ_GUEST_PASSWORD"'@g' $RABBIT_CONF

echo "Initializing RabbitMQ Data"
curl -v -u guest:guest -H "Content-Type: multipart/form-data" -H "Accept: application/json" -H "Expect:" -F file=@$RABBIT_CONF -X POST http://rabbitmq:15682/api/definitions

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

cat >/tmp/createUserIPP.js <<EOL
db.createUser(
  {
    user: "${MONGODB_IPP_USERNAME}",
    pwd: "${MONGODB_IPP_PASSWORD}",
    roles: [ { role: "readWrite", db: "lightsheet" } ],
    passwordDigestor : "server"
  });
EOL

for filename in /tmp/*.js; do
    mongo mongodb://${MONGODB_INIT_ROOT_USERNAME}:${MONGODB_INIT_ROOT_PASSWORD}@mongo1:27017,mongo2:27017,mongo3:27017/${MONGODB_INIT_DATABASE}?replicaSet=rsJacs $filename
    sleep 1
done

