# e.g.
#   countindex "logstash-2020.03"
#   countindex "logstash-2020.03.*"
index=$1
curl "http://e03u07:9200/${index}"/_count
