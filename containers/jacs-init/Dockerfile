FROM registry.int.janelia.org/scsw/builder

# Add Mongo
RUN apk add --no-cache mongodb python

# Add init scripts
RUN mkdir /app
WORKDIR /app
COPY init-filesystem /app/init-filesystem
COPY init-databases /app/init-databases

