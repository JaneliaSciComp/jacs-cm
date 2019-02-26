# JACS runs on port 8080
#
# When building, provide the following parameters:
#   --build-arg APP_TAG=<git tag for the jacs repo>
#
# When running, provide the -e hostname=host.int.janelia.org for the machine you're running on if you want Swagger UI to work. 
# If you're running in an orchestrated environment, you can simply set hostname to localhost.
#

# Builder container
FROM registry.int.janelia.org/scsw/builder as builder
ARG APP_TAG=master

# Checkout and build the code
WORKDIR /tmp
RUN git clone https://github.com/JaneliaSciComp/jacs-compute.git
WORKDIR /tmp/jacs-compute
RUN git checkout $APP_TAG
RUN gradle installDist

# Build the final container
FROM scientificlinux/sl:7
LABEL maintainer="rokickik@janelia.hhmi.org"
LABEL description="JACS Sync Services"
ENV HOSTNAME=localhost

# Install JRE for running
RUN yum install -y java-1.8.0-openjdk-headless

# Create jacs user (these can be overridden)
ARG UNAME=jacs
ARG GNAME=jacsdata
ARG UID=1047
ARG GID=1070
RUN groupadd -g $GID $GNAME && \
    useradd -m -u $UID -g $GID -s /bin/bash $UNAME

# Install the app
RUN mkdir /app && chown $UID:$GID /app

# Switch to jacs user and configure the app
USER $UNAME
ENV JAVA_HOME /usr/lib/jvm/jre
WORKDIR /app
COPY --from=builder /tmp/jacs-compute/jacs2-syncweb/build/install/jacs2-syncweb .

# Command for running the application
CMD [ "/app/bin/jacs2-syncweb", "-b", "0.0.0.0", "-s", "$HOSTNAME", "-p", "8080" ]
