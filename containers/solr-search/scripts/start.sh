#!/bin/bash

SEARCH_MAX_MEM_SIZE="${SEARCH_MAX_MEM_SIZE:-30}"

echo "SEARCH_MAX_MEM_SIZE=${SEARCH_MAX_MEM_SIZE}"

/opt/solr/bin/solr start -m ${SEARCH_MAX_MEM_SIZE}G "$@"
