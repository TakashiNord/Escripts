#!/bin/bash

# v.01 18/06/2021

# NAMES.DIRECTORY_PATH= (TNSNAMES, EZCONNECT)
# SQLNET.INBOUND_CONNECT_TIMEOUT=360
# SQLNET.RECV_TIMEOUT=10
# SQLNET.SEND_TIMEOUT=10

export PATH="/usr/local/bin:/usr/bin:/usr/X11R6/bin:/bin:/usr/lib/mit/bin:/usr/lib/mit/sbin:/opt/oracle/product/10g/bin"

LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH

export ORACLE_BASE=/opt/oracle
export ORACLE_HOME=$ORACLE_BASE/product/10g
export ORACLE_SID=rsdu1
export ORA_NLS10=$ORACLE_HOME/nls/data
export TNS_ADMIN=/opt/oracle/product/10g/network/admin
LD_LIBRARY_PATH=${LD_LIBRARY_PATH:+$LD_LIBRARY_PATH:}$ORACLE_HOME/lib
export LD_LIBRARY_PATH

# export NLS_LANG="RUSSIAN_CIS.CL8MSWIN1251"
export NLS_LANG="AMERICAN_AMERICA.CL8MSWIN1251"

spcalc ( )
{
sqlplus -s -L /nolog<<SQL
connect rsduadmin/passme ;
    set echo off;
    set pagesize 0;
    set feedback off;
    set trimout on;
    set linesize 300;
-- SPOOL sp.txt APP
SELECT count(*) FROM v\$process P, v\$session S WHERE  P.ADDR = S.PADDR
union all
SELECT count(*) FROM v\$process
union all
SELECT count(*) FROM v\$session;
SELECT S.SID,
       P.SPID,
       S.OSUSER,
       S.PROGRAM,
	   S.PADDR,
       S.status
     , i.instance_name
FROM v\$process P, v\$session S
     , v\$instance i
WHERE  P.ADDR = S.PADDR;
-- SPOOL OFF
exit
SQL
}

main ()
{
  echo -e "-------------" $( date )
  tRes=0
  res1=$( spcalc );
  # res2=`(echo ${res1} | fmt -su)`
  echo -e  "$res1"
  # if [ "${tRes}" -eq -1 ]
  # then
  #   echo " Error ."
  #   sudo sgtest 1372 1371 256 908 0
  # fi

}


main ;
exit 0;