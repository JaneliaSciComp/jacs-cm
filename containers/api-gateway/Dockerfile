FROM registry.int.janelia.org/scsw/builder as builder
ARG TAG_NGINX_JWT=master
ARG API_GATEWAY_EXPOSED_HOST=`hostname`

# Checkout the nginx-gwt module
WORKDIR /tmp
COPY ./conf/dashboard/settings.json /tmp/dashboard-settings.json

RUN git clone https://github.com/JaneliaSciComp/nginx-jwt.git
WORKDIR /tmp/nginx-jwt
RUN git checkout $TAG_NGINX_JWT && ./build

# Checkout jacs-dashboard
WORKDIR /tmp
RUN git clone https://github.com/JaneliaSciComp/jacs-dashboard.git

WORKDIR /tmp/jacs-dashboard
RUN sed s/%API%/$API_GATEWAY_EXPOSED_HOST/ /tmp/dashboard-settings.json > /tmp/jacs-dashboard/src/settings.json
RUN cat /tmp/jacs-dashboard/src/settings.json

RUN apk add python nodejs npm make g++ # Necessary for node-gyp

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

