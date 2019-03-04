#
# When building, expects the TAG_LDAP_JWT argument for which git tag to use.
#
# When running, expects an environment variable called JWT_SECRET
#

# Builder container
FROM node:6.9.2 as builder
ARG TAG_LDAP_JWT=master
RUN apt-get install git-core
WORKDIR /tmp

# Checkout and build the code
RUN git clone https://github.com/JaneliaSciComp/ldap-jwt.git
WORKDIR /tmp/ldap-jwt
RUN git checkout $TAG_LDAP_JWT
RUN npm install

# Build the final container
FROM node:6.9.2
LABEL maintainer="rokickik@janelia.hhmi.org"
LABEL description="LDAP/AD Authentication Service"
ADD VERSION .
COPY --from=builder /tmp/ldap-jwt /app
COPY ./start.sh /app/
WORKDIR /app
CMD [ "/bin/bash", "/app/start.sh" ]
EXPOSE 3000

