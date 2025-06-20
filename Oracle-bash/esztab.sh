#!/bin/bash

# v.01 26/07/2019

export PATH="/usr/local/bin:/usr/bin:/usr/X11R6/bin:/bin:/usr/lib/mit/bin:/usr/lib/mit/sbin:/opt/oracle/product/10g/bin"

LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH

export ORACLE_BASE=/opt/oracle
export ORACLE_HOME=$ORACLE_BASE/product/10g
export ORACLE_SID=rsdu
export ORA_NLS10=$ORACLE_HOME/nls/data
export TNS_ADMIN=/opt/oracle/product/10g/network/admin
LD_LIBRARY_PATH=${LD_LIBRARY_PATH:+$LD_LIBRARY_PATH:}$ORACLE_HOME/lib
export LD_LIBRARY_PATH

# tablespaces
TABS=(
RSDU_AUDIT
RSDU_CLARH_IND
RSDU_CLARH_TAB
RSDU_DAARH_IND
RSDU_DAARH_TAB
RSDU_ELARH_IND
RSDU_ELARH_TAB
RSDU_ELINSTARH_IND
RSDU_ELINSTARH_IND
RSDU_IND
RSDU_JOUR_IND
RSDU_JOUR_TAB
RSDU_PHARH_IND
RSDU_PHARH_TAB
RSDU_PSARH_IND
RSDU_PSARH_TAB
RSDU_TABL
RSDU_DAINSTARH_IND
RSDU_DAINSTARH_TAB
RSDU_ELINSTARH_TAB
RSDU_ELINSTARH_TAB
);


szcalc ( )
{
 tabl=$1
sqlplus -s -L  rsduadmin/"passme"@rsdu  << SQL
    set echo off;
    set tab off;
    set pagesize 0;
    set feedback off;
    set trimout on;
    set heading off;
    SELECT trunc(sum(bytes/1024),0) 
    FROM dba_free_space
    WHERE tablespace_name='$tabl';
SQL
}

main ()
{
  echo -e "-------------" $( date )
  tRes=0
  idx=0
  while test $idx -lt  ${#TABS[@]}; do
    src=${TABS[$idx]}
    res1=$( szcalc $src );
    res2=`(echo ${res1} | fmt -su)`
    echo -e  "$src = $res2"
    if [[ "${res2}"  =~ ^[0-9\.]+$ ]]; then
    :
    else
      tRes=-1
    fi
    if [ ${res2} -lt 49 ]; then
      tRes=-1
    fi
    let idx=idx+1
  done
  if [ "${tRes}" -eq -1 ]
  then
     echo " Error tablespace sizing."
     sudo sgtest 1372 1371 256 908 0
  fi

} 
 
main ;
exit 0;