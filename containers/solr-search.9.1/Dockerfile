FROM solr:9.1.1

LABEL maintainer="rokickik@janelia.hhmi.org"
LABEL description="JACS Solr Search Service"

# Install app
WORKDIR /app

COPY ./solr /app/solr
COPY ./conf /usr/local/tomcat/conf
COPY ./scripts/start.sh /app/start.sh
RUN chmod 755 /app/start.sh

# Our Solr deployment requires 30GB of memory
# The environment variables below are used to set JAVA_OPTS
ENV SEARCH_INIT_MEM_SIZE="10"
ENV SEARCH_MAX_MEM_SIZE="30"

# Required for faster startup (https://wiki.apache.org/tomcat/HowTo/FasterStartUp)
ENV CATALINA_OPTS="-Djava.security.egd=file:/dev/./urandom"

CMD ["/app/start.sh", "run"]
