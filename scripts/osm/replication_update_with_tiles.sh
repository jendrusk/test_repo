#!/bin/bash

now=$(date +"%Y%m%d")
logfile="OSM_Replication-$now.log"
logpath="/srv/logs/"

echo '-------------------START' >> $logpath$logfile 2>&1
date >> $logpath$logfile 2>&1

cd $(dirname $0)

set -e

onexit() {
    local x=$?
#    if [ $x -ne 0 ]; then
#        tail -n 100 /home/osm/logs/$logfile|mail -s "Błąd replikacji danych OSM" andrzej@abakus.net.pl
#    fi
}

trap "onexit" exit

(
	# Try to lock on the lock file (fd 200)

	flock -x -n 200 || exit 0

	if [ ! -f current.osc ]; then
		echo "No current.osc file found, downloading new one..." >> $logpath$logfile 2>&1
		osmosis --read-replication-interval --simc --write-xml-change current.osc >> $logpath$logfile 2>&1
	fi

	./osm2pgsql --number-processes 2 -v -C 2000 -G -K -j -x -s \
          -S /srv/src/openstreetmap-carto/openstreetmap-carto.style \
          --tag-transform-script /srv/src/openstreetmap-carto/openstreetmap-carto.lua --append -d gis  \
          --expire-tiles 10-20 --expire-output /srv/scripts/osm/expire_list_tmp \
          current.osc >> $logpath$logfile 2>&1

	if [ "$?" = "0" ]; then
		echo "Success, removing current.osc" >> $logpath$logfile  2>&1
		rm current.osc >> $logpath$logfile  2>&1
		echo "Done" >> $logpath$logfile  2>&1
	fi


	if [ -f /srv/scripts/osm/expire_list_tmp ]; then
	    cat /srv/scripts/osm/expire_list_tmp|sort|uniq|/usr/local/bin/render_expired --min-zoom=10 --max-zoom=20 --num-threads=6 --map ajt --touch-from=13 --delete-from=16 >> $logpath$logfile 2>&1 &&\
	    rm -f /srv/scripts/osm/expire_list_tmp >> $logpath$logfile 2>&1
	fi

) 200>/srv/scripts/osm/.replication.lock



date >> $logpath$logfile  2>&1
echo '-------------------STOP' >> $logpath$logfile 2>&1

