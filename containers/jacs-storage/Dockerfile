# Build the jade agent container
FROM janeliascicomp/builder:1.1.0 as builder
ARG APP_TAG=s3-support

# Checkout and build the code
RUN mkdir /tmp/jade
WORKDIR /tmp/jade
RUN echo "Cloning $APP_TAG branch"
RUN git clone --branch $APP_TAG --depth 1 https://github.com/JaneliaSciComp/jacs-storage.git . \
    && ./gradlew --no-daemon distTar installDist -x test \
    && ./gradlew -q printVersion > version
RUN mkdir client \
    && tar xf ./jacsstorage-clients/build/distributions/jacsstorage-clients-`cat version`.tar --strip-components=1 --directory client

# Build the final container
FROM oraclelinux:9

LABEL maintainer="goinac@janelia.hhmi.org"
LABEL description="JADE - JACS Storage Engine"

# Install JRE for running
RUN yum install -y java-1.8.0-openjdk-headless

# Install the app
RUN mkdir /app
ENV JAVA_HOME /usr/lib/jvm/jre
WORKDIR /app
COPY --from=builder /tmp/jade/jacsstorage-masterweb/build/install/jacsstorage-masterweb ./master
COPY --from=builder /tmp/jade/jacsstorage-agentweb/build/install/jacsstorage-agentweb ./agent
COPY --from=builder /tmp/jade/client ./client
COPY start.sh /app/

# Service mode defaults to client, but can be set to master or agent to run a server
ENV SERVICE_MODE=client
# These variables must be set when running this container in agent mode
ENV JADE_AGENT_EXPOSED_HOST=localhost
ENV JADE_AGENT_EXPOSED_PORT=9880
ENV JADE_MASTER_URL=http://jade-master:8080/jacsstorage/master_api/v1

# Command for running the application
CMD ["/bin/sh", "/app/start.sh"]
