FROM registry.int.janelia.org/scsw/builder

ARG TAG_MESSAGING=master

# Setup SSH for github access
ARG SSH_PRIVATE_KEY
RUN mkdir /root/.ssh/
RUN echo "${SSH_PRIVATE_KEY}" > /root/.ssh/id_dsa
RUN chmod 700 /root/.ssh/id_dsa
RUN ssh-keyscan -t rsa github.com >> ~/.ssh/known_hosts

# Add Mongo (it's the wrong version, but Alpine doesn't have 3.2)
RUN apk add --no-cache mongodb

# Add init script
RUN mkdir /app
WORKDIR /app
COPY init.sh /app/
COPY mongo /app/mongo

# Prereqs for RabbitMQ
RUN git clone git@github.com:JaneliaSciComp/jacs-messaging.git
WORKDIR /app/jacs-messaging
RUN git checkout $TAG_MESSAGING

CMD ["/app/init.sh"]

