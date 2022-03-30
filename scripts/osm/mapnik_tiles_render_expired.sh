#!/bin/bash
set -e
now=$(date +"%Y%m%d")

logname="OSM_Tiles_mapnik-expire-$now.log"
logpath="/srv/logs"
logfile="${logpath}/${logname}"
tmpdir="/zfs/pool-nvme/sort"
expireddir="/srv/logs/expired-tiles"
expiredhist="${expireddir}/expired.list"
workfile="${expireddir}/${now}.expired.work"

cd $expireddir



(
flock -x -n 201 || { echo "no lock" >&2; exit 0; }

echo "##--- START @ ${now}" | tee -a $logfile

FILTER=$(find $expireddir -type f ! -size 0 \( -name "*.expired" \) )

if [ -z "${FILTER}" ]; then
    echo "No files to work with or all empty. Exiting."
    exit 0
fi

echo "agregate all .expired to ${workfile}"
for f in `ls -1 -v *.expired`
do
    echo "Appendind data from $f ..." | tee -a $logfile
    wc -l $f | awk '{print $2" "$1}' >> ${expiredhist}
    if [ ! -s $f ]
    then
        rm $f
    else
        cat $f >> ${workfile} && rm $f
    fi
done

echo "sorting to ${workfile}.sorted"
nice -5 sort -S 1000000 -u -t"/" -k1,1n -k2,2n -k 3,3n -T $tmpdir ${workfile} > ${workfile}.sorted
echo "sorted."
rm -v ${workfile} | tee -a $logfile

workfile="${workfile}.sorted"

echo -e "===\nrender_expired base" | tee -a $logfile
set -o pipefail
cat $workfile | sudo /usr/local/bin/render_expired -t /srv/mapnik/mod_tile -m base --min-zoom=5 --max-zoom=18 --touch-from=5 --num-threads=4 | grep -v "Read and expanded" | tee -a $logfile
PGOUT=$?
set +o pipefail

if [[ $PGOUT != 0 ]]; then
    echo "render_expired PGOUT=${PGOUT}"| tee -a $logfile
    exit $PGOUT
fi


echo -e "===\nrender_expired emergency" | tee -a $logfile
set -o pipefail
cat $workfile | sudo /usr/local/bin/render_expired -t /srv/mapnik/mod_tile -m emergency --min-zoom=5 --max-zoom=18 --touch-from=5 --num-threads=4 | grep -v "Read and expanded" | tee -a $logfile
PGOUT=$?
set +o pipefail

if [[ $PGOUT != 0 ]]; then
    echo "render_expired PGOUT=${PGOUT}"| tee -a $logfile
    exit $PGOUT
fi

echo "Ignoring render_expired regions - only manual"
#echo -e "===\nrender_expired regions" | tee -a $logfile
#set -o pipefail
#cat $workfile | sudo /usr/local/bin/render_expired -t /srv/mapnik/mod_tile -m regions --min-zoom=5 --max-zoom=18 --touch-from=5 --num-threads=4 | grep -v "Read and expanded" | tee -a $logfile
#PGOUT=$?
#set +o pipefail
#
#if [[ $PGOUT != 0 ]]; then
#    echo "render_expired PGOUT=${PGOUT}"| tee -a $logfile
#    exit $PGOUT
#fi


echo -e "===\nall tasks done"
rm -v ${workfile} | tee -a $logfile

now=$(date +"%Y%m%dT%H%M%S")
echo "##--- STOP  @ ${now}" | tee -a $logfile

)201>$expireddir/.expire.lock

