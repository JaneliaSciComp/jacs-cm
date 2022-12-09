# Host to export from
kibanaHost=$1
shift

# what is one of config, index-pattern, search, dashboard, url, visualization
what=$1
shift

mkdir -p local/data

curl http://${kibanaHost}:5601/api/saved_objects/_export -H 'kbn-xsrf: true' \
     -H 'Content-Type: application/json' \
     -d "{\"type\": \"${what}\" }" > local/data/kibana-$what.ndjson
