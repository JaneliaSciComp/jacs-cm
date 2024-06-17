FROM mongo:4.4.11 as builder
LABEL maintainer="rokickik@janelia.hhmi.org"
LABEL description="One-shot initialization procedures for JACS deployments"

# Add Mongo
# RUN apk add --no-cache mongodb mongodb-tools python
RUN apt-get update
RUN apt-get install -y curl

# Add init scripts
RUN mkdir /app
WORKDIR /app
COPY filesystem /app/filesystem
COPY databases /app/databases

