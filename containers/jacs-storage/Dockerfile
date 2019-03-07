# Build the jade agent container
FROM registry.int.janelia.org/scsw/builder as builder
ARG APP_TAG=master

# Checkout and build the code
RUN mkdir /tmp/jade
WORKDIR /tmp/jade
RUN git clone https://github.com/JaneliaSciComp/jacs-storage.git .
RUN git checkout $APP_TAG
RUN ./gradlew installDist -x test

# Build the final container
FROM scientificlinux/sl:7
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
COPY start.sh /app/

# Expose port
EXPOSE 8080

# Service mode defaults to master node, but can be set to agent
ENV SERVICE_MODE=master
# These variables must be set when running this container in agent mode
ENV JADE_AGENT_EXPOSED_HOST=localhost
ENV JADE_AGENT_EXPOSED_PORT=9880
ENV JADE_MASTER_URL=http://jade-master:8080/jacsstorage/master_api/v1

# Command for running the application
CMD ["/bin/sh", "/app/start.sh"]

