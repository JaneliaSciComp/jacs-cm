# JACS Messaging runs on port 8080
#
# When building, provide the following parameters:
#   --build-arg APP_TAG=<git tag for the jacs repo>
#

# Builder container
FROM janeliascicomp/builder:1.0.0 as builder
ARG APP_TAG=master

# Checkout and build the code
WORKDIR /tmp/jacs-messaging
RUN git clone --branch $APP_TAG --depth 1 https://github.com/JaneliaSciComp/jacs-messaging.git . \
    && ./gradlew --no-daemon brokerJar

# Build the final container
FROM oraclelinux:9
LABEL maintainer="schauderd@janelia.hhmi.org"
LABEL description="JACS Messaging"

# Install JRE for running
RUN yum install -y java-1.8.0-openjdk-headless

# Configure the app
ENV JAVA_HOME /usr/lib/jvm/jre
WORKDIR /app
COPY --from=builder /tmp/jacs-messaging/jacs-messaging-broker/build/libs/sharedWorkspaceBroker*.jar /app/sharedWorkspaceBroker.jar
COPY logback.xml /app

# Command for running the application
ENV SYSTEM_OWNER=group:workstation-users
ENV NEURON_BROKER_BACKUP_QUEUE=
ENV INDEXING_BROKER_BACKUP_QUEUE=

CMD /usr/bin/java -Dlogback.configurationFile=/app/logback.xml \
-jar /app/sharedWorkspaceBroker.jar \
-ms ${RABBITMQ_HOSTNAME} \
-u ${RABBITMQ_USER} \
-p ${RABBITMQ_PASSWORD} \
-DneuronBroker.persistenceServer=${JACS_URL} \
-DneuronBroker.sharedSpaceOwner=${SYSTEM_OWNER} \
-DneuronBroker.backupLocation=${NEURON_BROKER_BACKUP_QUEUE} \
-DindexingBroker.indexingServer=${JACS_URL} \
-DindexingBroker.backupQueue=${INDEXING_BROKER_BACKUP_QUEUE}
