#!/bin/bash

echo "Running jacs-compute container image with service mode: ${SERVICE_MODE}"

if [[ "$SERVICE_MODE" = "async" ]]; then
    /app/async/bin/jacs2-asyncweb -b 0.0.0.0 -p 8080 -s "${HOSTNAME}"
elif [[ "$SERVICE_MODE" = "sync" ]]; then
    /app/sync/bin/jacs2-syncweb -b 0.0.0.0 -p 8080 -s "${HOSTNAME}"
else
    echo "Unsupported service mode specified (with SERVICE_MODE environment variable): ${SERVICE_MODE}"
    exit 1
fi
