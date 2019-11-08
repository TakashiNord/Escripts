set serveroutput on size 80000
set trimout on
set linesize 160
set pagesize 1000

define DBowner=&1
define DBpswd=&2
define DBname=&3
define TblLstName=&4
define DBArcName='&5'

spool MEASARC_ADD.&DBname..&TblLstName..log

conn &DBowner/&DBpswd@&DBname

@@MEASARC_ADD.sql

spool off
exit;
