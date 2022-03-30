#!/bin/bash
set -e
#exit 1
now=$(date +"%Y%m%dT%H%M%S")

logname="OSM_Tiles_render_old-$now.log"
logpath="/srv/logs"
logfile="${logpath}/${logname}"


SCRIPT_DIR="$( cd "$( dirname "$0" )" && pwd )"
#echo $SCRIPT_DIR
cd $SCRIPT_DIR


(
flock -x -n 201 || { echo "no lock" >&2; exit 0; }
echo "##--- START @ ${now}" | tee -a $logfile

echo "render old" | tee -a $logfile
assumedt=$(date --date="5 days ago" +%d/%m/%y)
set -o pipefail
#/usr/local/bin/render_old -c /usr/local/etc/renderd.conf -t /srv/mapnik/mod_tile --timestamp=${assumedt} --min-zoom=5 --max-zoom=17 --num-threads=4 | tee -a $logfile

/usr/local/bin/render_old -c /usr/local/etc/renderd.conf -t /srv/mapnik/mod_tile --min-zoom=5 --max-zoom=17 --num-threads=4 | tee -a $logfile
PGOUT=$?
set +o pipefail

if [[ $PGOUT != 0 ]]; then
    echo "render_old PGOUT=${PGOUT}"| tee -a $logfile
    exit $PGOUT
fi
echo "render_old done" | tee -a $logfile

now=$(date +"%Y%m%dT%H%M%S")
echo "##--- STOP  @ ${now}" | tee -a $logfile

)201>${SCRIPT_DIR}/.render_old.lock

