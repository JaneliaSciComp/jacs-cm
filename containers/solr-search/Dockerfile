FROM solr:9.1.1

LABEL maintainer="rokickik@janelia.hhmi.org"
LABEL description="JACS Solr Search Service"

# Install app
WORKDIR /app

COPY ./scripts/start.sh /app/start.sh

# Our Solr deployment requires 30GB of memory
# The environment variables below are used to set JAVA_OPTS
ENV SEARCH_INIT_MEM_SIZE="10"
ENV SEARCH_MAX_MEM_SIZE="30"

CMD ["/app/start.sh"]
