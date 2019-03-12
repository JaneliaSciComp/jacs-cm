FROM registry.int.janelia.org/jacs/builder

# Add Mongo
RUN apk add --no-cache mongodb mongodb-tools python

# Add init scripts
RUN mkdir /app
WORKDIR /app
COPY filesystem /app/filesystem
COPY databases /app/databases

