#!/bin/bash

export mysqldumpdir="/mysql-dump/mysqldump-backups"

docker exec flyportal_db_1 sh -c 'exec mysqldump --all-databases -uroot -p"$MYSQL_ROOT_PASSWORD"' | gzip > /${mysqldumpdir}/flyportal-$(date +%Y%m%d%H%M%S).sql.gz
