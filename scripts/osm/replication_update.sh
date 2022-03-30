#!/bin/bash

now=$(date +"%Y%m%d")
nowprec=$(date +"%Y%m%dT%H%M%S")
logfile="OSM_Replication-$now.log"
logpath="/srv/logs/"
exiredlist="/srv/logs/expired-tiles/${nowprec}.expired"


echo '-------------------START' >> $logpath$logfile 2>&1
date >> $logpath$logfile 2>&1

cd $(dirname $0)

set -e

onexit() {
    local x=$?
    if [ $x -ne 0 ]; then
        tail -n 100 $logpath$logfile|mail -s "Błąd replikacji danych OSM" andrzej@abakus.net.pl
    fi
}

trap "onexit" exit

(
	# Try to lock on the lock file (fd 200)

	flock -x -n 200 || exit 0

	if [ ! -f current.osc ]; then
		echo "No current.osc file found, downloading new one..." >> $logpath$logfile 2>&1
		osmosis/bin/osmosis --read-replication-interval --write-xml-change current.osc >> $logpath$logfile 2>&1
	fi

	/usr/bin/osm2pgsql --number-processes 1 -v -C 2000 -G -K -j -x -s \
          -S ./default.style --append -d osm2pgsql --bbox 13.50,48.50,24.50,55.50  \
          --expire-tiles 5-17 --expire-output ${exiredlist}.tmp \
          current.osc >> $logpath$logfile 2>&1

	if [ "$?" = "0" ]; then
		echo "saving housenumber changes" >> $logpath$logfile  2>&1

		#extractvars='-v "@id" -o "," -v "@uid" -o "," -v "@changeset" -o "," -v "@timestamp" -o "," -v "@lat" -o "," -v "@lon" -n'
		#set -x
		set +e 
		extractvarsway='-v @id -o , -v @uid -o , -v @changeset -o , -v @timestamp -o ,, -n'
		extractvarsnode='-v @id -o , -v @uid -o , -v @changeset -o , -v @timestamp -o , -v @lat -o , -v @lon -n'
		cat current.osc | xmlstarlet select -t -m '//way[tag/@k="addr:housenumber"]'  -o "way,"  ${extractvarsway} >> osc.housenumber.log
		cat current.osc | xmlstarlet select -t -m '//node[tag/@k="addr:housenumber"]' -o "node," ${extractvarsnode} >> osc.housenumber.log
		#set +x
		set -e

		echo "Success, removing current.osc" >> $logpath$logfile  2>&1
		rm current.osc >> $logpath$logfile  2>&1
		#psql -q -c "REFRESH MATERIALIZED VIEW view_amenities;" osm2pgsql
		#psql -q -c "REFRESH MATERIALIZED VIEW view_places;" osm2pgsql

		echo "Done" >> $logpath$logfile  2>&1
		mv ${exiredlist}.tmp ${exiredlist}
		touch /srv/mapnik/mod_tile/planet-import-complete

	fi
) 200>.replication.lock


#(
#flock -x -n 201 || exit 0
#if [ -f expire_list_tmp ]; then
#  cat expire_list_tmp >> expire_list &&\
#  rm -f expire_list_tmp
#fi
#
#)201>.expire.lock

echo "Replication lag:" >> $logpath$logfile
osmosis/bin/osmosis --rrl humanReadable=yes >> $logpath$logfile  2>/dev/null

date >> $logpath$logfile  2>&1
echo '-------------------STOP' >> $logpath$logfile 2>&1

