FROM janeliascicomp/builder:1.0.0 as builder
# Currently, this container must be build with a hardcoded exposed host.
# In the future this will be externalized as a runtime environment variable.
ARG API_GATEWAY_EXPOSED_HOST=localhost
ARG APP_TAG=master

# Checkout the code
RUN mkdir /tmp/jacs-dashboard
WORKDIR /tmp/jacs-dashboard
RUN git clone --branch $APP_TAG --depth 1 https://github.com/JaneliaSciComp/jacs-dashboard.git .

# Build the code
RUN apk add --no-cache python nodejs npm make g++ # Necessary for node-gyp
RUN npm install && npm run build

FROM nginx:stable
LABEL maintainer="goinac@janelia.hhmi.org"
LABEL description="JACS Dashboard"

COPY --from=builder /tmp/jacs-dashboard/build /var/www
COPY ./nginx.conf /etc/nginx/conf.d/default.conf
