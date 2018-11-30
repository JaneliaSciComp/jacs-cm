# JACS Messaging runs on port 8080
#
# When building, provide the following parameters:
#   --build-arg APP_TAG=<git tag for the jacs repo>
#   --build-arg SSH_PRIVATE_KEY=<your private key>
#

# Builder container
FROM registry.int.janelia.org/scsw/builder as builder
ARG APP_TAG=master

# Setup SSH for github access
ARG SSH_PRIVATE_KEY
RUN mkdir /root/.ssh/
RUN echo "${SSH_PRIVATE_KEY}" > /root/.ssh/id_dsa
RUN chmod 700 /root/.ssh/id_dsa
RUN ssh-keyscan -t rsa github.com >> ~/.ssh/known_hosts

# Checkout and build the code
WORKDIR /tmp
RUN git clone ssh://git@github.com/JaneliaSciComp/jacs-messaging.git
WORKDIR /tmp/jacs-messaging
RUN git checkout $APP_TAG
RUN ./gradlew brokerJar

# Build the final container
FROM scientificlinux/sl:7
LABEL maintainer="schauderd@janelia.hhmi.org"
LABEL description="JACS Messaging"

# Install JRE for running
RUN yum install -y java-1.8.0-openjdk-headless

# Create jacs user (these can be overridden)
ARG UNAME=jacs
ARG GNAME=jacsdata
ARG UID=1047
ARG GID=1070
RUN groupadd -g $GID $GNAME && \
    useradd -m -u $UID -g $GID -s /bin/bash $UNAME

# Install the app
RUN mkdir /app && chown $UID:$GID /app

# Switch to jacs user and configure the app
USER $UNAME
ENV JAVA_HOME /usr/lib/jvm/jre
WORKDIR /app
COPY --from=builder /tmp/jacs-messaging/build/libs/sharedWorkspaceBroker*.jar /app/sharedWorkspaceBroker.jar
COPY log4j2.properties /app

# Command for running the application
CMD /usr/bin/java -Dlog4j.configurationFile=file:/app/log4j2.properties \
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
