#!/bin/bash

echo "Running jacs-storage container image with service mode: $SERVICE_MODE"

if [[ "$SERVICE_MODE" = "master" ]]; then
    /app/master/bin/jacsstorage-masterweb -b 0.0.0.0 -p 8080

elif [[ "$SERVICE_MODE" = "agent" ]]; then
    /app/agent/bin/jacsstorage-agentweb -b 0.0.0.0 -p 8080 \
        -publicPort $JADE_AGENT_EXPOSED_PORT \
        -masterURL $JADE_MASTER_URL \
        -DStorageAgent.StorageHost=${JADE_AGENT_EXPOSED_HOST} \
        -DStorageAgent.InitialPingDelayInSeconds=10 \
        -bootstrapStorageVolumes
else
    echo "Unsupported service mode specified (with SERVICE_MODE environment variable): $SERVICE_MODE"
    exit 1
fi

