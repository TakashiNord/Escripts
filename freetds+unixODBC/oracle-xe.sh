export ORACLE_BASE=/opt/oracle
export ORACLE_HOME=$ORACLE_BASE/product/18c/dbhomeXE
export ORACLE_SID=XE
export NLS_LANG=AMERICAN_AMERICA.CL8MSWIN1251
export PATH=$ORACLE_HOME/bin:$PATH
export NLS_NUMERIC_CHARACTERS=".,"
export NLS_DATE_FORMAT="DD.MM.YYYY HH24:MI:SS"

alias alog='tail /opt/oracle/admin/XE/alert_XE.log'
alias alog2='alog -n 2000 | egrep -v "^  Current log# |^Thread 1 advanced to log sequence "'
alias sqlrsdu='sqlplus rsduadmin/passme@rsdu'
alias sqldba='sqlplus sys/passme18c@rsdu as sysdba'
