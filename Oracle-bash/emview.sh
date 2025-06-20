#!/bin/bash
export PATH="/usr/local/bin:/usr/bin:/usr/X11R6/bin:/bin:/usr/lib/mit/bin:/usr/lib/mit/sbin:/opt/oracle/product/10.2/db_1/bin"

LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH

 export ORACLE_BASE=/opt/oracle
 export ORACLE_HOME=$ORACLE_BASE/product/10.2/db_1
 export ORACLE_SID=rsduarc
 export ORA_NLS10=$ORACLE_HOME/nls/data
 export TNS_ADMIN=/opt/oracle/product/10.2/db_1/network/admin
 LD_LIBRARY_PATH=${LD_LIBRARY_PATH:+$LD_LIBRARY_PATH:}$ORACLE_HOME/lib
 export LD_LIBRARY_PATH

sqlplus /nolog<<EOF
connect rsduadmin/passme
exec RSDUADMIN.RSDUARC_REFRESH_MVIEWS_IF ;
exit
EOF


rem cron  15 */2 * * * 	
rem sqlplus / as sysdba
rem exec rsduadmin.rsduarc_refresh_mviews;
rem execute dbms_mview.refresh('rsduadmin.meas_snapshot30_tune');

