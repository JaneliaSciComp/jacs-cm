FROM janeliascicomp/builder:1.1.0 as builder
LABEL maintainer="rokickik@janelia.hhmi.org"
LABEL description="One-shot initialization procedures for JACS deployments"

# Add Mongo
RUN apk add --no-cache mongodb mongodb-tools python py-pip

# Add rotate-backups -> /usr/local/bin/rotate-backups
RUN pip install rotate-backups

# Add init scripts
RUN mkdir /app
WORKDIR /app
COPY filesystem /app/filesystem
COPY databases /app/databases
