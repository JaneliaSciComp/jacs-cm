#!/bin/bash

echo "Running jacs-async container image"

cd /app/async && bin/jacs2-asyncweb -b 0.0.0.0 -p 8080 -s "${HOSTNAME}"
