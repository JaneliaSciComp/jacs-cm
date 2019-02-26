ARG VERSION=6.5.4
FROM docker.elastic.co/elasticsearch/elasticsearch:$VERSION

# Create jacs user (these can be overridden)
ARG UNAME=jacs
ARG GNAME=jacsdata
ARG UID=1047
ARG GID=1070
RUN groupadd -g $GID $GNAME && \
    useradd -m -u $UID -g $GID -s /bin/bash $UNAME

RUN chown -R $UNAME:$GNAME /usr/share/elasticsearch && \
    chown $UNAME:$GNAME /usr/local/bin/docker-entrypoint.sh
RUN sed -i -e "s/--userspec=1000/--userspec=$UID/g" \
           -e "s/UID 1000/UID $UID/" \
           -e "s/chown -R 1000/chown -R $UID/" /usr/local/bin/docker-entrypoint.sh

