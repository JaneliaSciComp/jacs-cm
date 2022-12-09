# Host to import into
kibanaHost=$1
shift

# what is one of config, index-pattern, search, dashboard, url, visualization
what=$1
shift

curl -X POST http://${kibanaHost}:5601/api/saved_objects/_import \
     -H 'kbn-xsrf: true' \
     --form file=@local/data/kibana-${what}.ndjson
