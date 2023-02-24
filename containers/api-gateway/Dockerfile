FROM janeliascicomp/builder:1.0.0 as builder
ARG TAG_NGINX_JWT=master

# Checkout the nginx-gwt module
WORKDIR /tmp/nginx-jwt
RUN git clone https://github.com/JaneliaSciComp/nginx-jwt.git . \
    && git fetch --tags \
    && git checkout $TAG_NGINX_JWT \
    && ./build

# Checkout IPP
WORKDIR /tmp
RUN git clone https://github.com/JaneliaSciComp/lightsheet-pipeline.git

# Build the final container
FROM openresty/openresty:1.21.4.1-6-centos7
LABEL maintainer="rokickik@janelia.hhmi.org"
LABEL description="JACS API Gateway"
RUN mkdir /app
COPY --from=builder /tmp/nginx-jwt/nginx-jwt.lua /usr/local/openresty/site/lualib/
COPY --from=builder /tmp/nginx-jwt/lib/ /usr/local/openresty/site/lualib/
COPY --from=builder /tmp/lightsheet-pipeline/lightsheetInterface/app/static /app/ipp
COPY ./conf/nginx/ /usr/local/openresty/nginx/conf/
COPY ./html/ /usr/local/openresty/nginx/html/

WORKDIR /usr/local/openresty/nginx/tmp
RUN mkdir -p client-body proxy fastcgi uwsgi scgi

# Runtime configuration
WORKDIR /app
COPY start.sh /app/
EXPOSE 443
EXPOSE 80

CMD ["/bin/sh", "/app/start.sh"]
