FROM registry.int.janelia.org/scsw/builder

# Add Mongo
RUN apk add --no-cache mongodb mongodb-tools python

# Add init scripts
RUN mkdir /app
WORKDIR /app
COPY filesystem /app/filesystem
COPY databases /app/databases

