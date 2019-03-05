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
LABEL description="Jade Storage (Agent)"

# Install JRE for running
RUN yum install -y java-1.8.0-openjdk

# Install the app
RUN mkdir /app

# Switch to jacs user and configure the app
ENV JAVA_HOME /usr/lib/jvm/jre
WORKDIR /app
COPY --from=builder /tmp/jade/jacsstorage-agentweb/build/install/jacsstorage-agentweb .

# Expose port
EXPOSE 8080

# These variables must be set when running this container
ENV JADE_AGENT_EXPOSED_HOST=
ENV JADE_AGENT_EXPOSED_PORT=
ENV JADE_MASTER_URL=

# Command for running the application
CMD ["sh", "-c", "/app/bin/jacsstorage-agentweb -b 0.0.0.0 -p 8080 -publicPort $JADE_AGENT_EXPOSED_PORT -masterURL $JADE_MASTER_URL -DStorageAgent.StorageHost=${JADE_AGENT_EXPOSED_HOST} -DStorageAgent.InitialPingDelayInSeconds=10 -bootstrapStorageVolumes"]

