# JACS runs on port 8080
#
# When building, provide the following parameters:
#   --build-arg APP_TAG=<git tag for the jacs repo>
#   --build-arg SSH_PRIVATE_KEY=<your private key>
#
# When running, provide the -e hostname=host.int.janelia.org for the machine you're running on if you want Swagger UI to work. 
# If you're running in an orchestrated environment, you can simply set hostname to localhost.
#

# Builder container
FROM registry.int.janelia.org/scsw/builder as builder
ARG TAG_JACS=master

# Setup SSH for github access
ARG SSH_PRIVATE_KEY
RUN mkdir /root/.ssh/
RUN echo "${SSH_PRIVATE_KEY}" > /root/.ssh/id_dsa
RUN chmod 700 /root/.ssh/id_dsa
RUN ssh-keyscan -t rsa github.com >> ~/.ssh/known_hosts

# Checkout and build the code
WORKDIR /tmp
RUN git clone ssh://git@github.com/JaneliaSciComp/jacs.git
WORKDIR /tmp/jacs
RUN git checkout $TAG_JACS
RUN ./gradlew installDist

# Build the final container
FROM scientificlinux/sl:7
LABEL maintainer="rokickik@janelia.hhmi.org"
LABEL description="JACS Async Services"
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
COPY --from=builder /tmp/jacs/jacs2-asyncweb/build/install/jacs2-asyncweb .

# Command for running the application
CMD [ "/app/bin/jacs2-asyncweb", "-b", "0.0.0.0", "-s", "$HOSTNAME", "-p", "8080" ]
