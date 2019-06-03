# JACS runs on port 8080
#
# When building, provide the following parameters:
#   --build-arg APP_TAG=<git tag for the jacs repo>
#
# When running, provide the -e hostname=host.int.janelia.org for the machine you're running on if you want Swagger UI to work. 
# If you're running in an orchestrated environment, you can simply set hostname to localhost.
#

# Builder container
FROM janeliascicomp/builder:1.1.0 as builder
ARG APP_TAG=master

# Checkout and build the code
WORKDIR /tmp/jacs-compute
RUN git clone --branch $APP_TAG --depth 1 https://github.com/JaneliaSciComp/jacs-compute.git . \
    && ./gradlew --no-daemon installDist -x test

# Build the final container
FROM scientificlinux/sl:7
LABEL maintainer="goinac@janelia.hhmi.org"
LABEL description="JACS Sync Services"
ENV HOSTNAME=localhost

# Install JRE for running
RUN yum install -y java-1.8.0-openjdk-headless

# Install the app
RUN mkdir /app
ENV JAVA_HOME /usr/lib/jvm/jre
WORKDIR /app
COPY --from=builder /tmp/jacs-compute/jacs2-asyncweb/build/install/jacs2-asyncweb ./async
COPY --from=builder /tmp/jacs-compute/jacs2-syncweb/build/install/jacs2-syncweb ./sync
COPY start.sh /app/

# Service mode defaults to async node, but can be set to sync
ENV SERVICE_MODE=async

# Command for running the application
CMD ["/bin/sh", "/app/start.sh"]
