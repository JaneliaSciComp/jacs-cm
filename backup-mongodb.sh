#!/bin/bash

mongodumpdir="/mongo-dump/mongodump-backup"

docker run --rm -i \
           --volume ${mongodumpdir}:/backup \
           --user "4444:4444" \
           mongo:4.0 \
           bash -c 'mongodump --uri "mongodb://root:XXXXXX@mongodb4:27020,mongodb4:27021,mongodb4:27022/?replicaSet=rsJade&authSource=admin&readPreference=secondary" --archive=/backup/jade-$(date +%Y%m%d%H%M%S).archive'
