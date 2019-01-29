FROM registry.int.janelia.org/scsw/builder as builder
ARG TAG_NGINX_JWT=master

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
COPY ./html/ /usr/local/openresty/nginx/html/

# Runtime configuration
RUN mkdir /app
WORKDIR /app
COPY start.sh /app/
EXPOSE 443
EXPOSE 80

CMD ["/bin/sh", "/app/start.sh"]

