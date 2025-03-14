curl -X PUT -H 'Content-Type: application/json' \
     http://e03u07:9200/_cluster/settings \
     -d \
'
{
  "persistent": {
      "cluster.max_shards_per_node": 3100
  }
}
'
