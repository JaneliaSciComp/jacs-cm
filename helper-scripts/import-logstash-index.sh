#!/bin/bash

fromHost=$1
toHost=$2
indexName=$1

curl -H 'Content-Type: application/json' -X POST http://${toHost}9200/_reindex -d "{
    \"source\": {
        \"remote\": {
            \"host\": \"http://${fromHost}:9200\"
        },
        \"index\": \"${indexName}\",
        \"query\": {
            \"match_all\": {}
        }
    },
    \"dest\": {
        \"index\": \"${indexName}\"
    }
}"
