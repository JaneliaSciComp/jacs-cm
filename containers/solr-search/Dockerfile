# Tomcat runs on port 8080
# Solr is found at http://hostname:8080/solr/admin/

FROM tomcat:7.0.90-jre7
LABEL maintainer="rokickik@janelia.hhmi.org"
LABEL description="JACS Solr Search Service"

# Install app
RUN mkdir /app
COPY ./solr /app/solr
COPY ./conf /usr/local/tomcat/conf

WORKDIR /app

# Our Solr deployment requires 30GB of memory
ENV JAVA_OPTS="-XX:+UseConcMarkSweepGC -Xms10G -Xmx30G"

# Required for faster startup (https://wiki.apache.org/tomcat/HowTo/FasterStartUp)
ENV CATALINA_OPTS="-Djava.security.egd=file:/dev/./urandom"

