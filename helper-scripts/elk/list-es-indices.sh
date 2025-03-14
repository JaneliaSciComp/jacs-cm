esHost=$1
shift

esPort=${1:-9200}
shift

curl http://${esHost}:${esPort}/_cat/indices/$*
