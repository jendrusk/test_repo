#!/bin/bash

#lckdo -q -x /tmp/pg-db.lock || (echo "grabbing lock failed"; exit 1)

now=$(date +"%Y%m%d")
logpath="/srv/logs"
logfile="${logpath}/DB_Cleaning-$now.log"

set -e

onexit() {
    local x=$?
    if [ $x -ne 0 ]; then
        cat $logfile | mail -s "Błąd tworzenia pliku offline" andrzej@abakus.net.pl
    fi
}

trap "onexit" EXIT

set -o pipefail
psql -e -d osm2pgsql -a -f /srv/scripts/sql/cleaning.sql 2>&1 | ts -s "%H:%M:%S> " |tee -a $logfile
set +o pipefail


