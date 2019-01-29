FROM registry.int.janelia.org/scsw/builder

ARG TAG_MESSAGING=master

# Add Mongo (it's the wrong version, but Alpine doesn't have 3.2)
RUN apk add --no-cache mongodb

# Add init script
RUN mkdir /app
WORKDIR /app
COPY init.sh /app/
COPY mongo /app/mongo

# Prereqs for RabbitMQ
RUN git clone https://github.com/JaneliaSciComp/jacs-messaging.git
WORKDIR /app/jacs-messaging
RUN git checkout $TAG_MESSAGING

CMD ["/app/init.sh"]

