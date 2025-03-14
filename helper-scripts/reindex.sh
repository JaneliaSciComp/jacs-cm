# e.g. reindex.sh 2020 06
y=$1
m=$2

curl -X POST -H 'Content-Type: application/json' \
     http://e03u07:9200/_reindex \
     -d \
"
{
  \"source\": {
    \"index\": \"logstash-$y.$m.*\"
  },
  \"dest\": {
    \"index\": \"logstash-$y.$m\"
  }
}
"
