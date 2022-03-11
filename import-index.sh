indexName=$1

curl -H 'Content-Type: application/json' -X POST http://e03u08.int.janelia.org:9200/_reindex -d "{
    \"source\": {
	\"remote\": {
	    \"host\": \"http://c13u08.int.janelia.org:9200\"
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
