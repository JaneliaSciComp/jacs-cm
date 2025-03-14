# e.g. delete-shards.sh 2020 01
y=$1
m=$2
ds=(01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31)
for d in ${ds[@]}; do
  curl -X DELETE "http://e03u07:9200/logstash-$y.$m.$d"
done
