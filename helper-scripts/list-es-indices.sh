esHost=$1
esPort=${2:-9200}

curl http://${esHost}:${esPort}/_cat/indices
