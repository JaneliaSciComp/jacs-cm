esHost=$1

curl http://${esHost}:9200/_cat/indices
