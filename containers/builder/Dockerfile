FROM alpine:3.8
LABEL maintainer="rokickik@janelia.hhmi.org"
LABEL description="Tiny builder image which includes bash, git and other useful tools"
RUN apk update && apk upgrade && \
    apk add --no-cache bash git curl openssh libressl sed grep bc coreutils openjdk8 gradle npm

