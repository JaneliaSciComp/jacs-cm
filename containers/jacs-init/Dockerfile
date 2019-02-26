FROM registry.int.janelia.org/scsw/builder

ARG TAG_MESSAGING=master

# Add Mongo
RUN apk add --no-cache mongodb

# Add init script
RUN mkdir /app
WORKDIR /app
COPY init-filesystem /app/init-filesystem
COPY init-databases /app/init-databases

# Prereqs for RabbitMQ
RUN git clone https://github.com/JaneliaSciComp/jacs-messaging.git
WORKDIR /app/jacs-messaging
RUN git checkout $TAG_MESSAGING

