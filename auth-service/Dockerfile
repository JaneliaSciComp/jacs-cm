#
# When building, expects the SSH_PRIVATE_KEY variable
#
# When running, expects an environment variable called JWT_SECRET
#

# Builder container
FROM node:6.9.2 as builder
ARG SSH_PRIVATE_KEY
ARG TAG_LDAP_JWT=master
RUN apt-get install git-core
WORKDIR /tmp

# Setup SSH for github access
RUN mkdir /root/.ssh/
RUN echo "${SSH_PRIVATE_KEY}" > /root/.ssh/id_dsa
RUN chmod 700 /root/.ssh/id_dsa
RUN ssh-keyscan -t rsa github.com >> ~/.ssh/known_hosts

# Checkout and build the code
RUN git clone https://github.com/JaneliaSciComp/ldap-jwt.git
WORKDIR /tmp/ldap-jwt
RUN git checkout $TAG_LDAP_JWT
RUN npm install

# Build the final container
FROM node:6.9.2
LABEL maintainer="rokickik@janelia.hhmi.org"
LABEL description="JACS Authentication Service"
ADD VERSION .
COPY --from=builder /tmp/ldap-jwt /app
COPY ./config.json /app/config/config.json
COPY ./start.sh /app/
WORKDIR /app
CMD [ "/bin/bash", "/app/start.sh" ]
EXPOSE 3000

