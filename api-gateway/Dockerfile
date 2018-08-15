FROM registry.int.janelia.org/scsw/builder as builder
ARG SSH_PRIVATE_KEY
ARG TAG_NGINX_JWT=master

# Setup SSH for github access
RUN mkdir /root/.ssh/
RUN echo "${SSH_PRIVATE_KEY}" > /root/.ssh/id_dsa
RUN chmod 700 /root/.ssh/id_dsa
RUN ssh-keyscan -t rsa github.com >> ~/.ssh/known_hosts

# Checkout and build the code
WORKDIR /tmp
RUN git clone https://github.com/JaneliaSciComp/nginx-jwt.git
WORKDIR /tmp/nginx-jwt
RUN git checkout $TAG_NGINX_JWT
RUN ./build

# Build the final container
FROM openresty/openresty:1.13.6.2-centos
LABEL maintainer="rokickik@janelia.hhmi.org"
LABEL description="JACS API Gateway"
COPY --from=builder /tmp/nginx-jwt/nginx-jwt.lua /usr/local/openresty/site/lualib/
COPY --from=builder /tmp/nginx-jwt/lib/ /usr/local/openresty/site/lualib/
COPY ./conf/ /usr/local/openresty/nginx/conf/

# Runtime configuration
WORKDIR /pp
RUN mkdir /app
COPY start.sh /app/
EXPOSE 443
EXPOSE 80

CMD ["/bin/sh", "/app/start.sh"]

