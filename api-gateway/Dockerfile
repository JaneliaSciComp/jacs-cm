FROM registry.int.janelia.org/scsw/builder as builder
ARG TAG_NGINX_JWT=master

# Checkout the nginx-gwt module
WORKDIR /tmp
RUN git clone https://github.com/JaneliaSciComp/nginx-jwt.git
WORKDIR /tmp/nginx-jwt
RUN git checkout $TAG_NGINX_JWT && ./build

# Checkout jacs-dashboard
WORKDIR /tmp
RUN git clone https://github.com/JaneliaSciComp/jacs-dashboard.git
COPY ./conf/dashboard/ /tmp/jacs-dashboard/src/
WORKDIR /tmp/jacs-dashboard
RUN apk add python make g++ # Necessary for node-gyp
RUN npm install && npm run build

# Checkout IPP
WORKDIR /tmp
RUN git clone https://github.com/JaneliaSciComp/lightsheet-pipeline.git

# Build the final container
FROM openresty/openresty:1.13.6.2-centos
LABEL maintainer="rokickik@janelia.hhmi.org"
LABEL description="JACS API Gateway"
RUN mkdir /app
COPY --from=builder /tmp/nginx-jwt/nginx-jwt.lua /usr/local/openresty/site/lualib/
COPY --from=builder /tmp/nginx-jwt/lib/ /usr/local/openresty/site/lualib/
COPY --from=builder /tmp/jacs-dashboard/build /app/jacs-dashboard
COPY --from=builder /tmp/lightsheet-pipeline/lightsheetInterface/app/static /app/ipp
COPY ./conf/nginx/ /usr/local/openresty/nginx/conf/
COPY ./html/ /usr/local/openresty/nginx/html/

# Runtime configuration
WORKDIR /app
COPY start.sh /app/
EXPOSE 443
EXPOSE 80

CMD ["/bin/sh", "/app/start.sh"]

