FROM janeliascicomp/builder:1.0.0 as builder
# Currently, this container must be build with a hardcoded exposed host.
# In the future this will be externalized as a runtime environment variable.
ARG API_GATEWAY_EXPOSED_HOST=localhost

WORKDIR /tmp
RUN git clone https://github.com/JaneliaSciComp/jacs-dashboard.git

WORKDIR /tmp/jacs-dashboard
COPY settings.json /tmp/dashboard-settings.json
RUN sed s/%API%/$API_GATEWAY_EXPOSED_HOST/ /tmp/dashboard-settings.json > /tmp/jacs-dashboard/src/settings.json
RUN cat /tmp/jacs-dashboard/src/settings.json
RUN apk add --no-cache python nodejs npm make g++ # Necessary for node-gyp
RUN npm install && npm run build

FROM nginx:stable
LABEL maintainer="goinac@janelia.hhmi.org"
LABEL description="JACS Dashboard"

RUN mkdir /app
COPY --from=builder /tmp/jacs-dashboard/build /var/www
COPY ./nginx.conf /etc/nginx/conf.d/default.conf
