FROM registry.int.janelia.org/scsw/builder

# Add Mongo
RUN apk add --no-cache mongodb python

# Add init scripts
RUN mkdir /app
WORKDIR /app
COPY filesystem /app/filesystem
COPY databases /app/databases

