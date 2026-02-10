FROM ubuntu:focal as builder
LABEL maintainer="rokickik@janelia.hhmi.org"
LABEL description="One-shot initialization procedures for JACS deployments"

# Add Mongo
RUN apt-get update
RUN apt-get install -y gnupg curl gettext-base

# Add MongoDB public GPG key (new keyserver)
RUN curl -fsSL https://pgp.mongodb.com/server-4.4.asc | gpg --dearmor -o /usr/share/keyrings/mongodb-archive-keyring.gpg

# Add MongoDB 4.4 repo using the new key
RUN echo "deb [arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-archive-keyring.gpg] \
    https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/4.4 multiverse" \
  | tee /etc/apt/sources.list.d/mongodb-org-4.4.list


# Update and install
RUN apt-get update && apt-get install -y mongodb-org

# Add init scripts
RUN mkdir /app
WORKDIR /app
COPY filesystem /app/filesystem
COPY databases /app/databases
