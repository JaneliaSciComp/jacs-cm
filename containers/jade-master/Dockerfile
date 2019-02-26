# Build the jade agent container
FROM registry.int.janelia.org/scsw/builder as builder
ARG APP_TAG=master

# Checkout and build the code
RUN mkdir /tmp/jade
WORKDIR /tmp/jade
RUN git clone https://github.com/JaneliaSciComp/jacs-storage.git .
RUN git checkout $APP_TAG
RUN ./gradlew installDist

# Build the final container
FROM scientificlinux/sl:7
LABEL maintainer="goinac@janelia.hhmi.org"
LABEL description="Jade Storage (Master)"

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
ENV JAVA_HOME=/usr/lib/jvm/jre
WORKDIR /app
COPY --from=builder /tmp/jade/jacsstorage-masterweb/build/install/jacsstorage-masterweb .

# Expose port
EXPOSE 8080

# Command for running the application
CMD ["/app/bin/jacsstorage-masterweb", "-b", "0.0.0.0", "-p", "8080"]
