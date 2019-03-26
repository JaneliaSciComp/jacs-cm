FROM alpine:3.8
LABEL maintainer="rokickik@janelia.hhmi.org"
LABEL description="Tiny builder image which includes bash, git and other useful tools"
RUN apk update && apk upgrade \
    # avoid "missing libnss3.so" error with Docker
    && apk add --no-cache nss \
    # shell tilities
    && apk add --no-cache bash sed grep bc jq coreutils \
    # envsubst
    && apk add --no-cache gettext libintl \
    # remote access
    && apk add --no-cache git curl openssh libressl \
    # Java builds
    && apk add --no-cache openjdk8 gradle maven \
    # node.js builds
    && apk add --no-cache npm
