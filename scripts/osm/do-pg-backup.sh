#!/bin/bash
#set -e
umask 027

dt=`date "+%Y%m%dT%H%M%S"`

db=osm2pgsql
#db=emptytstdb2

bkpdir="/srv/pg_backup"
bkpfile=${bkpdir}/${db}_${dt}.backup
logfile=${bkpdir}/${db}_${dt}.log



FREE=`df -k --output=avail ${bkpdir} | tail -n1`
if [[ $FREE -lt 42949672 ]]; then
   echo 'Kopia bazy wymaga przynajmniej 40GB miejsca w folderze'| tee -a $logfile
   exit 1
fi;

echo -e "###---- START ---- @ `date`" | tee -a $logfile
echo "db=${db}" | tee -a $logfile
echo "bkpfile=${bkpfile}" | tee -a $logfile
echo "logfile=${logfile}" | tee -a $logfile
echo -e "starting pg_dump ...\n" | tee -a $logfile

umask 027
#time(pg_dump --create --file=${bkpfile} --format=custom --no-owner --compress=3 --verbose osm2pgsql)>> $logfile 2>&1

set -o pipefail
pg_dump --create --file=${bkpfile} --format=custom --no-owner --verbose ${db} 2>&1 | ts -s "%H:%M:%S> " | tee -a $logfile
PGOUT=$?
set +o pipefail

if [[ $PGOUT != 0 ]]; then 
    echo "PGOUT=${PGOUT}"| tee -a $logfile
    exit $PGOUT
fi

bkp_count=`ls ${bkpdir}/${db}*.backup | wc -l`


if [ $bkp_count -gt 2 ];then
  oldest="$(ls -1t ${bkpdir}/${db}*.backup | tail -1)"
  echo "Usuwam stary backup: ${oldest}"| tee -a $logfile
  rm $oldest| tee -a $logfile
fi;

echo -e "###---- STOP ---- @ `date`" | tee -a $logfile

#do crona można wrzucić to - jeżeli pg_dump się wywali (i tylko wtedy) całość loga dotrze w emilu + będzie w logu
#chronic /srv/scripts/db/do-pg-backup.sh
