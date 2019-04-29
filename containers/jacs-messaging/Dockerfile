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
RUN git clone https://github.com/JaneliaSciComp/jacs-messaging.git . \
    && git fetch --tags \
    && git checkout $APP_TAG \
    && ./gradlew --no-daemon brokerJar

# Checkout wait-for-it
WORKDIR /tmp
RUN git clone https://github.com/vishnubob/wait-for-it.git

# Build the final container
FROM scientificlinux/sl:7
LABEL maintainer="schauderd@janelia.hhmi.org"
LABEL description="JACS Messaging"

# Install JRE for running
RUN yum install -y java-1.8.0-openjdk-headless

# Configure the app
ENV JAVA_HOME /usr/lib/jvm/jre
WORKDIR /app
COPY --from=builder /tmp/jacs-messaging/build/libs/sharedWorkspaceBroker*.jar /app/sharedWorkspaceBroker.jar
COPY --from=builder /tmp/wait-for-it/wait-for-it.sh /app
COPY log4j2.properties /app

# Command for running the application
ENV SYSTEM_OWNER=group:workstation-users
CMD bash /app/wait-for-it.sh $RABBITMQ_HOSTNAME:5672 --timeout=30 --strict -- \
/usr/bin/java -Dlog4j.configurationFile=file:/app/log4j2.properties \
-jar /app/sharedWorkspaceBroker.jar \
-rec UpdatesProcessor \
-send ModelRefresh \
-error ModelErrors \
-ms $RABBITMQ_HOSTNAME \
-ps $JACS_URL \
-u $RABBITMQ_USER \
-p $RABBITMQ_PASSWORD \
-systemOwner $SYSTEM_OWNER \
-backupQueue ClientRefresh \
-backupLocation /app/backup/backupQueue
