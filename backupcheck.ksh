#!/bin/bash
set -o vi

export DB_HOME=/u01/oracle/product/11.2.0.4/db
export ORACLE_HOME=$DB_HOME
export ASM_HOME=/u01/grid/oracle/product/11.2.0.4/grid
export GRID_HOME=/u01/grid/oracle/product/11.2.0.4/grid
export CRS_HOME=/u01/grid/oracle/product/11.2.0.4/grid
export TNS_ADMIN=$DB_HOME/network/admin
export PATH=$PATH:$DB_HOME/bin:$CRS_HOME/bin:$AGENT_HOME/bin:$ASM_HOME/bin.
export PATH_ORIG=$PATH
export HOST=`hostname`


COLUMNS=180

for a in $(ps -ef | grep pmon | grep -v ASM | grep -v rman | grep -v grep | grep -v sed | sed 's/.*ora_pmon_//')
do
export ORACLE_SID=$a
echo
$ORACLE_HOME/bin/sqlplus -s / as sysdba << NACHO > /tmp/${ORACLE_SID}_dbincr.log
set feedback off
select COUNT(*) from V\$RMAN_BACKUP_JOB_DETAILS where START_TIME >= sysdate -1 and INPUT_TYPE = 'DB INCR';
exit
NACHO

export DBINCRLOG=`grep -o ''0'' /tmp/${ORACLE_SID}_dbincr.log`

 if [[ $DBINCRLOG = "0" ]]
  then
        mail -s "${HOST} DB INCR Stop Running:${ORACLE_SID}" "joshua.gosserand@cerner.com" < /tmp/${ORACLE_SID}_dbincr.log
 fi

done

for a in $(ps -ef | grep pmon | grep -v ASM | grep -v rman | grep -v grep | grep -v sed | sed 's/.*ora_pmon_//')
do
export ORACLE_SID=$a
echo
$ORACLE_HOME/bin/sqlplus -s / as sysdba << NACHO > /tmp/${ORACLE_SID}_dbarccnt.log
set feedback off
select COUNT(*) from V$RMAN_BACKUP_JOB_DETAILS where to_char(START_TIME,'dd/mm/yyyy') = to_char(sysdate,'dd/mm/yyyy') and INPUT_TYPE = 'ARCHIVELOG';
exit
NACHO

export DBARCCNT=`grep -o ''0'' /tmp/${ORACLE_SID}_dbarccnt.log`

 if [[ $DBARCCNT = "0" ]]
  then
        mail -s "${HOST} DB Archivelogs Stop Running:${ORACLE_SID}" "joshua.gosserand@cerner.com" < /tmp/${ORACLE_SID}_dbarccnt.log
 fi

done
