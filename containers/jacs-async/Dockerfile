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
LABEL description="JACS Async Services"
ENV HOSTNAME=localhost

# Install JRE and singularity for running
RUN yum update -y && \
    yum install -y \
        yum-utils \
        device-mapper-persistent-data \
	lvm2 && \
    yum-config-manager --add-repo \
        https://download.docker.com/linux/centos/docker-ce.repo && \
    yum groupinstall -y 'Development Tools' && \
    yum install -y \
        docker-ce-stable docker-ce-cli \
        java-1.8.0-openjdk-headless \
        wget \
        libseccomp-devel \
        squashfs-tools \
        cryptsetup

WORKDIR /gopath

ENV GOPATH /gopath
ENV GOVERSION 1.17.4.linux-amd64
ENV PATH ${PATH}:/usr/local/go/bin:${GOPATH}/bin

RUN wget https://dl.google.com/go/go$GOVERSION.tar.gz && \
    tar -C /usr/local -xzvf go$GOVERSION.tar.gz && \
    rm go$GOVERSION.tar.gz

WORKDIR /app

ENV SINGULARITY_VERSION 3.9.1

VOLUME /var/lib/docker

RUN mkdir /singularity_install && \
    cd /singularity_install && \
    wget https://github.com/sylabs/singularity/releases/download/v${SINGULARITY_VERSION}/singularity-ce-${SINGULARITY_VERSION}.tar.gz && \
    rpmbuild -tb singularity-ce-${SINGULARITY_VERSION}.tar.gz && \
    rpm -ivh ~/rpmbuild/RPMS/x86_64/singularity-ce-$SINGULARITY_VERSION-1.el7.x86_64.rpm && \
    rm -rf ~/rpmbuild && \
    rm -rf /singularity_install

# Install the app
ENV JAVA_HOME /usr/lib/jvm/jre
COPY --from=builder /tmp/jacs-compute/jacs2-asyncweb/build/install/jacs2-asyncweb ./async
COPY start.sh /app/

# Command for running the application

CMD ["/bin/sh", "/app/start.sh"]

